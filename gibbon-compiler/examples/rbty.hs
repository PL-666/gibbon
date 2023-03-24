-- Written by jazullo.

import Gibbon.Maybe

data B = B Bool

tru :: B
tru = B True

fal :: B
fal = B False

unB :: B -> Bool
unB bPacked = case bPacked of
  B b -> b

data I = I Int
data O = Lt | Eq | Gt

unI :: I -> Int
unI iPacked = case iPacked of
  I i -> i

cmp :: I -> I -> O
cmp ip1 ip2 =
  let
    i1 = unI ip1
    i2 = unI ip2
  in if i1 < i2 then Lt
  else if i1 > i2 then Gt
  else Eq

data RBT
  = Empty
  | Node B I RBT RBT

empty :: RBT
empty = Empty

singleton :: I -> RBT
singleton x = Node tru x Empty Empty

insert :: I -> RBT -> RBT
insert e1 t = case t of
  Empty -> singleton e1
  Node colorx x left right ->
    flipColors (rotateRight (rotateLeft (case cmp x e1 of
      Gt -> Node colorx x left (insert e1 right)
      Lt -> Node colorx x (insert e1 left) right
      Eq -> t
    )))

rotateLeft :: RBT -> RBT
rotateLeft t = case t of
  Empty -> Empty
  Node colorx x leftx rightx -> case rightx of
    Empty -> t
    Node c z leftz rightz ->
      if isRed rightx && isBlack leftx
      then Node colorx z (Node tru x leftx leftz) rightz
      else t

rotateRight :: RBT -> RBT
rotateRight t = case t of
  Empty -> Empty
  Node colorx x leftx rightx -> case leftx of
    Empty -> t
    Node c y lefty righty ->
      if isRed leftx && isRed lefty
      then Node colorx y lefty (Node tru x righty rightx)
      else t

flipColors :: RBT -> RBT
flipColors t = case t of
  Empty -> Empty
  Node c x leftx rightx -> case leftx of
    Empty -> t
    Node c1 y lefty righty -> case rightx of
      Empty -> t
      Node c2 z leftz rightz ->
        if isRed leftx && isRed rightx
        then Node tru x (Node fal y lefty righty) (Node fal z leftz rightz)
        else t

isRed :: RBT -> Bool
isRed t = case t of
  Empty -> False
  Node c1 x l r -> unB c1

isBlack :: RBT -> Bool
isBlack t = case t of
  Empty -> True
  Node c1 x l r -> if unB c1 then False else True

ins :: Int -> RBT -> RBT
ins x t = insert (I x) (copyPacked t)

mini :: RBT -> I
mini t = case t of
  Empty -> I (0 - 1)
  Node c x l r -> case l of
    Empty -> x
    Node cl xl ll rl -> mini l

gibbon_main =
  let
    t1 = ins 5 empty
    t2 = ins 3 t1
    t3 = ins 8 t2
    t4 = ins 9 t3
    t5 = ins 4 t4
    t6 = ins 1 t5
    _ = printPacked t6
  in ()
