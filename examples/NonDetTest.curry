module NonDetTest where

coin = True ? False

goal0 = (\x -> (x,x)) coin

goal1 = (coin, coin)