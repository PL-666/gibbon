{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -fno-warn-name-shadowing #-}

-- | Tests for L2.Typecheck
--
module L2.Typecheck where

import Test.Tasty.HUnit
import Test.Tasty.TH
import Test.Tasty

import Control.Monad.Except
import Data.Set as S
import Data.Map as M

import Packed.FirstOrder.Common
import Packed.FirstOrder.L2.Syntax as L2
import Packed.FirstOrder.L2.Typecheck
import qualified Packed.FirstOrder.L1.Syntax as L1

--
import Common


-- | Run the typechecker for (Prog {ddefs = Tree, fundefs = [add1], mainExp = exp})
--
tester :: Exp2 -> Either TCError (Ty2, LocationTypeState)
tester = runExcept . (tcExp ddfs env funs constrs regs tstate)
  where
    ddfs    = ddtree
    env     = Env2 M.empty M.empty
    funs    = M.empty
    constrs = ConstraintSet S.empty
    regs    = RegionSet S.empty
    tstate  = LocationTypeState M.empty


-- |
assertValue :: Exp2 -> (Ty2, LocationTypeState) -> Assertion
assertValue exp expected =
  case tester exp of
    Left err -> assertFailure $ show err
    Right actual -> expected @=? actual


-- |
assertError :: Exp2 -> TCError -> Assertion
assertError exp expected =
  case tester exp of
    Left actual -> expected @=? actual
    Right err -> assertFailure $ show err


-- Tests

case_test1 :: Assertion
case_test1 = assertValue exp (IntTy,LocationTypeState {tsmap = M.fromList []})
  where exp = LitE 1


case_test2 :: Assertion
case_test2 =  assertValue exp (IntTy,LocationTypeState {tsmap = M.fromList []})
  where exp = LetE ("a",[],IntTy,LitE 1) (PrimAppE L1.AddP [VarE "a",VarE "a"])


case_test3 :: Assertion
case_test3 =  assertValue exp (IntTy,LocationTypeState {tsmap = M.fromList []})
  where exp = Ext $ LetRegionE (VarR "r") $ Ext $ LetLocE "l" (StartOfC "l" (VarR "r")) $ LitE 1


case_test4 :: Assertion
case_test4 =  assertValue exp (IntTy,LocationTypeState {tsmap = M.fromList []})
  where exp = Ext $ LetRegionE (VarR "r") $ Ext $ LetLocE "l" (StartOfC "l" (VarR "r")) $
              LetE ("throwaway", [], PackedTy "Tree" "l", DataConE "l" "Leaf" [LitE 1]) $ LitE 2


case_test4_error1 :: Assertion
case_test4_error1 =  assertError exp expected
  where exp = Ext $ LetRegionE (VarR "r") $
              Ext $ LetLocE "l" (StartOfC "l" (VarR "r1")) $
              LetE ("throwaway", [], PackedTy "Tree" "l",
                    DataConE "l" "Leaf" [LitE 1]) $ LitE 2

        expected = GenericTC "Region VarR (Var \"r1\") not in scope" (Ext (LetLocE (Var "l") (StartOfC (Var "l") (VarR (Var "r1"))) (LetE (Var "throwaway",[],PackedTy "Tree" (Var "l"),DataConE (Var "l") "Leaf" [LitE 1]) (LitE 2))))


case_test4_error2 :: Assertion
case_test4_error2 =  assertError exp expected
  where exp = Ext $ LetRegionE (VarR "r") $ Ext $
              LetLocE "l" (StartOfC "l" (VarR "r")) $
              LetE ("throwaway", [], PackedTy "Tree" "l1",
                    DataConE "l1" "Leaf" [LitE 1]) $ LitE 2

        expected = GenericTC "Unknown location Var \"l1\"" (DataConE (Var "l1") "Leaf" [LitE 1])


case_test5 :: Assertion
case_test5 =  assertValue exp (IntTy,LocationTypeState {tsmap = M.fromList []})
  where exp = Ext $ LetRegionE (VarR "r") $ Ext $ LetLocE "l" (StartOfC "l" (VarR "r")) $
              Ext $ LetLocE "l1" (AfterConstantC 1 "l" "l1") $
              LetE ("x", [], PackedTy "Tree" "l1", DataConE "l1" "Leaf" [LitE 1]) $
              Ext $ LetLocE "l2" (AfterVariableC "x" "l1" "l2") $
              LetE ("y", [], PackedTy "Tree" "l2", DataConE "l2" "Leaf" [LitE 2]) $
              LetE ("z", [], PackedTy "Tree" "l", DataConE "l" "Node" [VarE "x", VarE "y"]) $
              LitE 1

case_test5_error1 :: Assertion
case_test5_error1 =  assertError exp expected
  where exp = Ext $ LetRegionE (VarR "r") $
              Ext $ LetLocE "l" (StartOfC "l" (VarR "r")) $
              Ext $ LetLocE "l1" (AfterConstantC 1 "l" "l1") $
              LetE ("x", [], PackedTy "Tree" "l1", DataConE "l1" "Leaf" [LitE 1]) $
              Ext $ LetLocE "l2" (AfterVariableC "x" "l1" "l2") $
              LetE ("y", [], PackedTy "Tree" "l2", DataConE "l2" "Leaf" [LitE 2]) $
              LetE ("z", [], PackedTy "Tree" "l",
                    DataConE "l" "Node" [VarE "y", VarE "x"]) $ LitE 1

        expected = LocationTC "Expected after relationship" (DataConE (Var "l") "Node" [VarE (Var "y"),VarE (Var "x")]) (Var "l") (Var "l2")

case_test6 :: Assertion
case_test6 =  assertValue exp (IntTy,LocationTypeState {tsmap = M.fromList []})
  where exp = Ext $ LetRegionE (VarR "r") $ Ext $ LetLocE "l" (StartOfC "l" (VarR "r")) $
              Ext $ LetLocE "l1" (AfterConstantC 1 "l" "l1") $
              LetE ("x", [], PackedTy "Tree" "l1", DataConE "l1" "Leaf" [LitE 1]) $
              Ext $ LetLocE "l2" (AfterVariableC "x" "l1" "l2") $
              LetE ("y", [], PackedTy "Tree" "l2", DataConE "l2" "Leaf" [LitE 2]) $
              LetE ("z", [], PackedTy "Tree" "l", DataConE "l" "Node" [VarE "x", VarE "y"]) $
              CaseE (VarE "z") [ ("Leaf",[("num","lnum")], VarE "num")
                               , ("Node",[("x","lnodex"),("y","lnodey")], LitE 0)]


case_test7 :: Assertion
case_test7 = actualTest7 @=? expextedTest7
  where
    test7Prog :: L2.Prog
    test7Prog = Prog ddtree (M.singleton "add1" add1Fun) (Just (test7main,IntTy))

    actualTest7 :: L2.Prog
    actualTest7 = fst $ runSyM 0 $ tcProg test7Prog

    expextedTest7 :: L2.Prog
    expextedTest7 = L2.Prog {ddefs = M.fromList [(Var "Tree",DDef {tyName = Var "Tree", dataCons = [("Leaf",[(False,IntTy)]),("Node",[(False,PackedTy "Tree" (Var "l")),(False,PackedTy "Tree" (Var "l"))])]})], fundefs = M.fromList [(Var "add1",L2.FunDef {funname = Var "add1", funty = ArrowTy {locVars = [LRM (Var "lin") (VarR (Var "r1")) Input,LRM (Var "lout") (VarR (Var "r1")) Output], arrIn = PackedTy "Tree" (Var "lin"), arrEffs = S.fromList [Traverse (Var "lin")], arrOut = PackedTy "Tree" (Var "lout"), locRets = [EndOf (LRM (Var "lin") (VarR (Var "r1")) Input)]}, funarg = Var "tr", funbod = CaseE (VarE (Var "tr")) [("Leaf",[(Var "n",Var "l0")],LetE (Var "v",[],IntTy,PrimAppE L1.AddP [VarE (Var "n"),LitE 1]) (LetE (Var "lf",[],PackedTy "Tree" (Var "lout"),DataConE (Var "lout") "Leaf" [VarE (Var "v")]) (VarE (Var "lf")))),("Node",[(Var "x",Var "l1"),(Var "y",Var "l2")],Ext (LetLocE (Var "lout1") (AfterConstantC 1 (Var "lout") (Var "lout1")) (LetE (Var "x1",[],PackedTy "Tree" (Var "lout1"),AppE (Var "add1") [Var "l1",Var "lout1"] (VarE (Var "x"))) (Ext (LetLocE (Var "lout2") (AfterVariableC (Var "x1") (Var "lout1") (Var "lout2")) (LetE (Var "y1",[],PackedTy "Tree" (Var "lout2"),AppE (Var "add1") [Var "l2",Var "lout2"] (VarE (Var "y"))) (LetE (Var "z",[],PackedTy "Tree" (Var "lout"),DataConE (Var "lout") "Node" [VarE (Var "x1"),VarE (Var "y1")]) (VarE (Var "z")))))))))]})], mainExp = Just (Ext (LetRegionE (VarR (Var "r")) (Ext (LetLocE (Var "l") (StartOfC (Var "l") (VarR (Var "r"))) (Ext (LetLocE (Var "l1") (AfterConstantC 1 (Var "l") (Var "l1")) (LetE (Var "x",[],PackedTy "Tree" (Var "l1"),DataConE (Var "l1") "Leaf" [LitE 1]) (Ext (LetLocE (Var "l2") (AfterVariableC (Var "x") (Var "l1") (Var "l2")) (LetE (Var "y",[],PackedTy "Tree" (Var "l2"),DataConE (Var "l2") "Leaf" [LitE 1]) (LetE (Var "z",[],PackedTy "Tree" (Var "l"),DataConE (Var "l") "Node" [VarE (Var "x"),VarE (Var "y")]) (Ext (LetRegionE (VarR (Var "rtest")) (Ext (LetLocE (Var "testout") (StartOfC (Var "testout") (VarR (Var "rtest"))) (LetE (Var "a",[],PackedTy "Tree" (Var "testout"),AppE (Var "add1") [Var "l",Var "testout"] (VarE (Var "z"))) (CaseE (VarE (Var "a")) [("Leaf",[(Var "num",Var "lnum")],VarE (Var "num")),("Node",[(Var "x",Var "lnodex"),(Var "y",Var "lnodey")],LitE 0)])))))))))))))))),IntTy)}

    test7main :: Exp2
    test7main = Ext $ LetRegionE (VarR "r") $ Ext $ LetLocE "l" (StartOfC "l" (VarR "r")) $
                Ext $ LetLocE "l1" (AfterConstantC 1 "l" "l1") $
                LetE ("x", [], PackedTy "Tree" "l1", DataConE "l1" "Leaf" [LitE 1]) $
                Ext $ LetLocE "l2" (AfterVariableC "x" "l1" "l2") $
                LetE ("y", [], PackedTy "Tree" "l2", DataConE "l2" "Leaf" [LitE 1]) $
                LetE ("z", [], PackedTy "Tree" "l", DataConE "l" "Node" [VarE "x", VarE "y"]) $
                Ext $ LetRegionE (VarR "rtest") $
                Ext $ LetLocE "testout" (StartOfC "testout" (VarR "rtest")) $
                LetE ("a", [], PackedTy "Tree" "testout", AppE "add1" ["l","testout"] (VarE "z")) $
                CaseE (VarE "a") [ ("Leaf",[("num","lnum")], VarE "num")
                                 , ("Node",[("x","lnodex"),("y","lnodey")], LitE 0)]

l2TypecheckerTests :: TestTree
l2TypecheckerTests = $(testGroupGenerator)
