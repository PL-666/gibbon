{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes     #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE DeriveGeneric #-}

{-# OPTIONS_GHC -fno-warn-orphans #-}

-- |

module Packed.FirstOrder.Target
    (Var, Tag, Tail(..), Triv(..), Ty(..), Prim(..), FunDecl(..),
     codegenFun,
     -- Examples, temporary:
     exadd1, exadd1Tail, add1C
    ) where

--------------------------------------------------------------------------------

-- import GHC.Word
import Data.Word (Word8)
import Data.List (nub)

import Data.Loc (noLoc)
import Language.C.Quote.C (cexp, cstm, cdecl, cty, cfun, csdecl, cparam, cedecl) -- cinit, 
import qualified Language.C.Quote.C as C
import qualified Language.C.Syntax as C
-- import Language.C.Pretty
import Text.PrettyPrint.Mainland
import Packed.HigherOrder.L1_Source (T1 (..))

import Text.PrettyPrint.GenericPretty
import Prelude hiding (init)
    
--------------------------------------------------------------------------------
-- * AST definition

type Var = String
type Tag = Word8

data Triv
    = VarTriv Var
    | IntTriv Int
    | TagTriv Tag
  deriving (Show, Read, Ord, Eq, Generic)

-- deriving instance Generic Word8 -- Won't work even after importing GHC.Word
instance Out Word8 where
    doc       w = doc       (fromIntegral w :: Int)
    docPrec n w = docPrec n (fromIntegral w :: Int)
instance Out Triv
           
data Tail
    = RetValsT [Triv] -- ^ Only in tail position, for returning from a function.
    | LetCallT { binds  :: [(Var,Ty)],
                 rator  :: Var,
                 rands  :: [Triv],
                 typ    :: Ty,
                 tmpNam :: Maybe Var,  -- hack, needed a name for the returned struct, should gensym
                 bod    :: Tail }
    | LetPrimCallT { binds :: [(Var,Ty)],
                     prim  :: Prim,
                     rands :: [Triv],
                     bod   :: Tail }
    | Switch Triv [(Tag,Tail)] (Maybe Tail)
    -- ^ For casing on numeric tags.
    | TailCall Var [Triv]
  deriving (Show, Read, Ord, Eq, Generic)

instance Out Tail
           
data Ty
    = IntTy
    | TagTy -- ^ A single byte.
    | SymTy -- ^ Symbols used in writing compiler passes.
            --   It's an alias for Int, an index into a symbol table.
    | CursorTy -- ^ A byte-indexing pointer.
    | ProdTy [Ty]
    | SymDictTy T1
      -- ^ We allow built-in dictionaries from symbols to a value type.
  deriving (Show, Read, Ord, Eq, Generic)

instance Out Ty
           
data Prim
    = AddP
    | SubP
    | MulP
    | DictInsertP -- ^ takes k,v,dict
    | DictLookupP -- ^ takes k,dict, errors if absent
    | NewBuf 
    -- ^ Allocate a new buffer, return a cursor.
    | WriteTag
    -- ^ Write a static tag value, takes a cursor to target.
    | WriteInt
    -- ^ Write (leaf) data, takes cursor,int
    | ReadTag
    -- ^ Read one byte from the cursor and advance it.
    | ReadInt
      -- ^ Read an 8 byte Int from the cursor and advance.
  deriving (Show, Read, Ord, Eq, Generic)

instance Out Prim
           
data FunDecl = FunDecl Var [(Var,Ty)] Ty Tail
  deriving (Show, Read, Ord, Eq, Generic)

instance Out FunDecl

--------------------------------------------------------------------------------
-- * C codegen

-- newtype Cg = Cg { unwrapCg :: () }

codegenFun :: FunDecl -> ([C.Definition])
codegenFun (FunDecl nam args ty tal) =
    let retTy   = codegenTy ty
        params  = map (\(v,t) -> [cparam| $ty:(codegenTy t) $id:v |]) args
        body    = codegenTail tal retTy
        structs = makeStructs $ nub $ ty : (map snd args)
        fun = [cfun| $ty:retTy $id:nam ($params:params) {
                  $items:body
              } |]
    in structs ++ [(C.FuncDef fun noLoc)]

codegenTriv :: Triv -> C.Exp
codegenTriv (VarTriv v) = C.Var (C.toIdent v noLoc) noLoc
codegenTriv (IntTriv i) = [cexp| $i |]
codegenTriv (TagTriv i) = [cexp| $i |]

codegenTail :: Tail -> C.Type -> [C.BlockItem]
codegenTail (RetValsT [tr]) _ty = [ C.BlockStm [cstm| return $(codegenTriv tr); |] ]
codegenTail (RetValsT ts) ty =
    [ C.BlockStm [cstm| return $(C.CompoundLit ty args noLoc); |] ]
    where args = map (\a -> (Nothing,C.ExpInitializer (codegenTriv a) noLoc)) ts
codegenTail (Switch _tr [] Nothing) _ty = []
codegenTail (Switch _tr [] (Just t)) ty =
    codegenTail t ty
codegenTail (Switch _tr [(_ctag,ctail)] Nothing) ty =
    codegenTail ctail ty
codegenTail (Switch tr ((ctag,ctail):cs) def) ty =
    [ C.BlockStm $ C.If comp thenTail elseTail noLoc ]
    where comp = [cexp| $(codegenTriv tr) == $ctag |]
          thenTail = mkBlock $ codegenTail ctail ty
          elseTail = if (null cs) then Nothing else Just $ mkBlock $ codegenTail (Switch tr cs def) ty
codegenTail (TailCall v ts) _ty =
    [ C.BlockStm [cstm| return $( C.FnCall (cid v) args noLoc); |] ]
    where args = map codegenTriv ts
codegenTail (LetCallT bnds ratr rnds ty0 (Just nam) body) ty =
    let init = [ C.BlockDecl [cdecl| $ty:(codegenTy ty0) $id:nam = $(C.FnCall (cid ratr) (map codegenTriv rnds) noLoc); |] ]
        assn t x y = C.BlockDecl [cdecl| $ty:t $id:x = $exp:y; |]
        bind (v,t) f = assn (codegenTy t) v (C.Member (cid nam) (C.toIdent f noLoc) noLoc)
        fields = map (\(_,i) -> "field" ++ (show i)) $ zip bnds [0..]
    in init ++ (zipWith bind bnds fields) ++ (codegenTail body ty)
codegenTail (LetPrimCallT bnds prm rnds body) ty =
    let bod' = codegenTail body ty
        pre  = case prm of
                 AddP -> let [(outV,outT)] = bnds
                             [pleft,pright] = rnds
                         in [ C.BlockDecl [cdecl| $ty:(codegenTy outT) $id:outV = $(codegenTriv pleft) + $(codegenTriv pright); |] ]
                 SubP -> let (outV,outT) = head bnds
                             [pleft,pright] = rnds
                         in [ C.BlockDecl [cdecl| $ty:(codegenTy outT) $id:outV = $(codegenTriv pleft) - $(codegenTriv pright); |] ]
                 MulP -> let [(outV,outT)] = bnds
                             [pleft,pright] = rnds
                         in [ C.BlockDecl [cdecl| $ty:(codegenTy outT) $id:outV = $(codegenTriv pleft) * $(codegenTriv pright); |]]
                 DictInsertP -> undefined
                 DictLookupP -> undefined
                 NewBuf -> undefined
                 WriteTag -> let [(outV,CursorTy)] = bnds
                                 [(TagTriv tag),(VarTriv cur)] = rnds
                             in [ C.BlockStm [cstm| *($id:cur) = $tag; |]
                                , C.BlockDecl [cdecl| char* $id:outV = $id:cur + 1; |] ]
                 WriteInt -> let [(outV,CursorTy)] = bnds
                                 [val,(VarTriv cur)] = rnds
                             in [ C.BlockStm [cstm| *(int*)($id:cur) = $(codegenTriv val); |]
                                , C.BlockDecl [cdecl| char* $id:outV = ($id:cur) + sizeof(int); |] ]
                 ReadTag -> let [(tagV,TagTy),(curV,CursorTy)] = bnds
                                [(VarTriv cur)] = rnds
                            in [ C.BlockDecl [cdecl| $ty:(codegenTy TagTy) $id:tagV = *($id:cur); |]
                               , C.BlockDecl [cdecl| char* $id:curV = $id:cur + 1; |] ]
                 ReadInt -> let [(valV,IntTy),(curV,CursorTy)] = bnds
                                [(VarTriv cur)] = rnds
                            in [ C.BlockDecl [cdecl| int $id:valV = *(int*)($id:cur); |]
                               , C.BlockDecl [cdecl| char* $id:curV = ($id:cur) + sizeof(int); |] ]
    in pre ++ bod'

codegenTy :: Ty -> C.Type
codegenTy IntTy = [cty|int|]
codegenTy TagTy = [cty|int|]
codegenTy SymTy = [cty|int|]
codegenTy CursorTy = [cty|char*|]
codegenTy (ProdTy ts) = C.Type (C.DeclSpec [] [] (C.Tnamed (C.Id nam noLoc) [] noLoc) noLoc) (C.DeclRoot noLoc) noLoc 
    where nam = makeName ts
codegenTy (SymDictTy _t) = undefined

makeStructs :: [Ty] -> [C.Definition]
makeStructs [] = []
makeStructs ((ProdTy ts):ts') = 
    let d     = [cedecl| typedef struct $id:(nam ++ "_struct") { $sdecls:decls } $id:nam; |]
        nam   = makeName ts
        decls = map (\(t,n) -> [csdecl| $ty:(codegenTy t) $id:("field"++(show n)); |]) $ zip ts [0..]
    in d : (makeStructs ts')
makeStructs (_:ts) = makeStructs ts

makeName :: [Ty] -> String
makeName [] = "Prod"
makeName (IntTy:ts) = "Int" ++ makeName ts
makeName (CursorTy:ts) = "Cursor" ++ makeName ts
makeName _ = undefined
                                                        
mkBlock :: [C.BlockItem] -> C.Stm
mkBlock ss = C.Block ss noLoc

cid :: Var -> C.Exp
cid v = C.Var (C.toIdent v noLoc) noLoc

-- Examples:          
--------------------------------------------------------------------------------

leafTag :: Word8
leafTag = fromIntegral 0

nodeTag :: Word8
nodeTag = fromIntegral 1         

exadd1 :: FunDecl
exadd1 = FunDecl "add1" [("t",CursorTy),("tout",CursorTy)] (ProdTy [CursorTy,CursorTy]) exadd1Tail 

exadd1Tail :: Tail
exadd1Tail =
    LetPrimCallT [("ttag",TagTy),("t2",CursorTy)] ReadTag [VarTriv "t"]
  $ Switch (VarTriv "ttag")
           [(leafTag,leafCase),
            (nodeTag,nodeCase)]
           Nothing
    where leafCase =
              LetPrimCallT [("tout2",CursorTy)] WriteTag [TagTriv leafTag, VarTriv "tout"]
            $ LetPrimCallT [("n",IntTy),("t3",CursorTy)] ReadInt [VarTriv "t2"]
            $ LetPrimCallT [("n1",IntTy)] AddP [VarTriv "n", IntTriv 1]
            $ LetPrimCallT [("tout3",CursorTy)] WriteInt [VarTriv "n1", VarTriv "tout2"]
            $ RetValsT [VarTriv "t3", VarTriv "tout3"]
          nodeCase =
              LetPrimCallT [("tout2",CursorTy)] WriteTag [TagTriv nodeTag, VarTriv "tout"]
            $ LetCallT [("t3",CursorTy),("tout3",CursorTy)] "add1" [VarTriv "t2", VarTriv "tout2"] (ProdTy [CursorTy,CursorTy]) (Just "tmp1")
            $ TailCall "add1" [VarTriv "t3", VarTriv "tout3"]

-- | Compile the example and print it              
add1C :: IO ()
add1C = mapM_ (\c -> putDocLn $ ppr c) (codegenFun exadd1)
