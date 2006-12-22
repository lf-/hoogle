
module Hoogle.Query.Type where

import Data.Maybe

import Hoogle.General
import Hoogle.TypeSig.All


usefulQuery query = not (null (names query)) || isJust (typeSig query)


data Query = Query {
        scope :: [Scope],
        names :: [String],
        typeSig :: Maybe TypeSig,
        items :: [ItemType],
        flags :: [Flag]
    }
    deriving Show


instance Eq Query where
    (Query a1 b1 c1 d1 e1) == (Query a2 b2 c2 d2 e2) =
        and [a1 `setEq` a2, b1 `setEq` b2, c1 == c2, d1 `setEq` d2, e1 `setEq` e2]


data Scope = PlusPackage  String
           | MinusPackage String
           | PlusModule  [String]
           | MinusModule [String]
           deriving (Eq, Show, Read)


data ItemType = ItemModule
              | ItemType
              | ItemFunction
              | ItemClass
              deriving (Eq, Show, Read)

itemTypes =
    [(["module"], ItemModule)
    ,(["type","data"], ItemType)
    ,(["function","ctor","fun"], ItemFunction)
    ,(["class","instance"], ItemClass)
    ]


-- primarily for consoles, but some work on the web search
-- first is the name, second is optional data
data Flag = Flag String String
            deriving (Eq, Show, Read)
