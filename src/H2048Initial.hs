module H2048Initial where

{-
2048 game implementation on console

Based on:
A Haskell implementation of 2048.
Gregor Ulm
https://github.com/gregorulm/h2048
-}

import Prelude hiding (Left, Right)
import Data.Char (toLower)
import Data.List
import System.IO
import System.Random
import Text.Printf

type Grid = [[Int]]

main :: IO ()
main = do
    hSetBuffering stdin NoBuffering
    grid <- initialGrid
    gameLoop grid

initialGrid :: IO Grid
initialGrid = do
    grid1 <- addTile grid0
    grid2 <- addTile grid1
    return grid2

grid0 :: Grid
grid0 = replicate 4 [0, 0, 0, 0]

addTile :: Grid -> IO Grid
addTile grid = do
    let candidateTiles = getZeroes grid
    pickedTile <- choose candidateTiles
    value  <- choose [2,2,2,2,2,2,2,2,2,4]
    let newGrid = setTile pickedTile value grid
    return newGrid

getZeroes :: Grid -> [(Int, Int)]
getZeroes grid = [ (0,0) ]

{-
*H2048> getZeroes [ [0,0,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,0] ]
[(0,0),(0,1),(0,2),(0,3),(1,0),(1,1),(1,2),(1,3),(2,0),(2,1),(2,2),
(2,3),(3,0),(3,1),(3,2),(3,3)]

*H2048> getZeroes [ [0,0,2,0], [0,0,0,0], [0,0,0,0], [2,0,0,0] ]
[(0,0),(0,1),(0,3),(1,0),(1,1),(1,2),(1,3),(2,0),(2,1),(2,2),(2,3),
(3,1),(3,2),(3,3)]

*H2048> getZeroes [ [0,0,0,2], [0,0,2,4], [8,16,32,64], [128,256,512,1024] ]
[(0,0),(0,1),(0,2),(1,0),(1,1)]

*H2048> getZeroes [ [2,4,2,4], [4,8,4,8], [2,4,2,4], [16,8,16,8] ]
[]
-}

choose :: [a] -> IO a
choose xs = do
    i <- randomRIO (0, length xs-1)
    return (xs !! i)

setTile :: (Int, Int) -> Int -> Grid -> Grid
setTile (row, col) val grid = grid

{-
*H2048Initial> setTile (0,0) 2 [ [0,0,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,0] ]
[[2,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]

*H2048Initial> setTile (1,2) 4 [ [0,0,0,2], [0,0,0,4], [8,16,32,64],
 [128,256,512,1024] ]
[[0,0,0,2],[0,0,4,4],[8,16,32,64],[128,256,512,1024]]
-}

gameLoop :: Grid -> IO ()
gameLoop grid
    | areMovesPossible grid = do
        printGrid grid
        if check2048 grid
        then putStrLn "You won!"
        else do newGrid <- getNewGrid grid
                if grid /= newGrid
                then do new <- addTile newGrid
                        gameLoop new
                else gameLoop grid
    | otherwise = do
        printGrid grid
        putStrLn "Game over"

data Move = Up | Down | Left | Right

areMovesPossible :: Grid -> Bool
areMovesPossible grid = False

{-
*H2048Initial> areMovesPossible grid0
True
*H2048Initial> areMovesPossible [[2,4,2,4],[4,8,4,8],[2,4,2,4],[4,8,4,8]]
False
*H2048Initial> areMovesPossible [[2,4,2,4],[8,4,8,4],[2,4,2,4],[4,8,4,8]]
True
-}

printGrid :: Grid -> IO ()
printGrid grid = do
    clearScreen
    mapM_ printRow grid

clearScreen :: IO ()
clearScreen = putStr "\ESC[2J\ESC[2J\n" -- clears the screen

printRow :: [Int] -> IO ()
printRow = foldr (\r rs -> printf "%5d" r >> rs) (putStr "\n")

check2048 :: Grid -> Bool
check2048 grid = False

{-
*H2048Initial> check2048 [ [0,0,0,2], [0,0,0,4], [8,16,32,64], [128,256,512,1024] ]
False
*H2048Initial> check2048 [ [0,0,0,2], [0,0,0,4], [8,16,32,64], [128,256,512,2048] ]
True
-}

getNewGrid :: Grid -> IO Grid
getNewGrid grid = do
    move <- captureMove
    let newGrid = applyMove move grid
    return newGrid

captureMove :: IO Move
captureMove = do
    inp <- getChar
    case lookup (toLower inp) moves of
        Just move  -> return move
        Nothing -> do putStrLn "Use WASD or CHTN as input"
                      captureMove

moves :: [(Char, Move)]
moves = keys "wasd" ++ keys "chtn"
    where keys chars = zip chars [Up, Left, Down, Right]

applyMove :: Move -> Grid -> Grid
applyMove Left  = map merge
applyMove Right = map (reverse . merge . reverse)
applyMove Up    = transpose . applyMove Left  . transpose
applyMove Down  = transpose . applyMove Right . transpose

merge :: [Int] -> [Int]
merge xs = id xs

{-
*H2048Initial> merge [0,0,2,4]
[2,4,0,0]
*H2048Initial> merge [0,2,2,4]
[4,4,0,0]
*H2048Initial> merge [2,2,2,4]
[4,2,4,0]
*H2048Initial> merge [2,2,4,4]
[4,8,0,0]
*H2048Initial> merge [2,4,4,4]
[2,8,4,0]
-}
