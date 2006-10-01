
module Hoogle.DataBase.Type(
    DataBase(..), ItemId, createDataBase, loadDataBase,
    searchName
    ) where

import Data.IORef
import System.IO
import Control.Monad

import Hoogle.DataBase.Alias
import Hoogle.DataBase.Kinds
import Hoogle.DataBase.Instances
import Hoogle.DataBase.Items
import Hoogle.DataBase.Modules
import Hoogle.DataBase.Texts
import Hoogle.TextBase.All

import General.All


hooVersion = 1 :: Int
hooString = "HOOG"


type Pending x = IORef (Either Int x)
type ItemId = Int


data DataBase = DataBase {
                    handle  :: Handle,
                    package :: String,
                    version :: String,
                    
                    -- the static and cached information
                    modules :: Pending Modules, -- Prelude, Data.Map etc.
                    kinds :: Pending Kinds, -- [] 1, Ord 1
                    alias :: Pending Alias, -- type String = [Char]
                    instances :: Pending Instances, -- instance Ord Bool
                    
                    -- the dynamic information
                    nameSearchPos, typeSearchPos :: Int
                }


-- [] is success
-- (_:_) are the error messages
createDataBase :: TextBase -> FilePath -> IO [Response]
createDataBase tb file = do
    hndl <- openBinaryFile file WriteMode
    hPutStr hndl hooString
    hPutInt hndl 0 -- 0 for binary notice
    hPutInt hndl hooVersion -- verson number

    hPutString hndl "package"
    hPutString hndl "1.0"

    tablePos <- hGetPosn hndl
    replicateM_ 6 $ hPutInt hndl 0

    posModule <- hTellInt hndl
    tb2 <- saveModules hndl tb
    tb3 <- saveItems hndl tb2
    
    (pos, err) <-
        mapAndUnzipM (\x -> do y <- hTellInt hndl ; z <- x ; return (y,z))
            [saveKinds hndl tb
            ,saveAlias hndl tb
            ,saveInstances hndl tb
            ,saveTexts hndl tb3
            ,return [] -- save types
            ]
    
    hSetPosn tablePos
    mapM_ (hPutInt hndl) (posModule:pos)
    hClose hndl
    
    return $ map Warn $ concat err


loadDataBase :: FilePath -> IO (Maybe DataBase)
loadDataBase file = do
    hndl <- openBinaryFile file ReadMode
    str <- hGetStr hndl (length hooString)
    zero <- hGetInt hndl
    ver <- hGetInt hndl
    
    if str /= hooString || zero /= 0 || ver /= hooVersion then return Nothing else do
        
        package <- hGetString hndl
        version <- hGetString hndl
        
        [a,b,c,d,e,f] <- replicateM 6 $ hGetInt hndl
        a2 <- gen a; b2 <- gen b; c2 <- gen c; d2 <- gen d
        
        return $ Just $ DataBase hndl package version a2 b2 c2 d2 e f
    where
        gen :: Int -> IO (IORef (Either Int a))
        gen i = newIORef (Left i)



-- forward methods
searchName :: DataBase -> String -> IO [(Int,Bool,Int)]
searchName database str = do
    let hndl = handle database
    hSeek hndl AbsoluteSeek (toInteger $ nameSearchPos database)
    searchTexts hndl str
