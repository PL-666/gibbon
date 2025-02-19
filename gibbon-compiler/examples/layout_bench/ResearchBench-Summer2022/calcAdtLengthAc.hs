module Main where

import Strings
import Contents
import Adts                             

-- Recursive function to get length
getLength :: Adt -> Int
getLength adt = case adt of 
                     Nil              -> 0
                     AC next content  -> 1 + getLength next
                                         

-- Tail recursice function to get length, using the tail recursice version
getLengthTR :: Adt -> Int -> Int
getLengthTR adt accumulator = case adt of 
                                         Nil -> accumulator
                                         AC next content -> getLengthTR next (1+accumulator)
                            


-- This is an example testing the performance of the AC style layout
-- AC -> next Adt first, Content comes after the Adt
-- This example simply counts the length of this Abstract Data type
-- The Adt layout AC is theoretically suppoed to be faster since that layout will traverse a much smaller part of the list. It only needs to keep traversing next until it hits Nil.
-- At which point it can termintate and not traverse the content part.
                            
gibbon_main = 
    let ac = mkACList 100 10
        count1 = getLengthTR ac 0
    in count1 == 100
