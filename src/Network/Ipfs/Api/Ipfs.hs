{-# LANGUAGE BangPatterns          #-}
{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE TypeOperators         #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
-- |
-- Module      :  Network.Ipfs.Api.Ipfs
-- Copyright   :  Alexander Krupenkin 2016-2018
-- License     :  BSD3
--
-- Maintainer  :  mail@akru.me
-- Stability   :  experimental
-- Portability :  unknown
--
-- Module containing Ipfs command functions.
--

module Network.Ipfs.Api.Ipfs where

import qualified Codec.Archive.Tar            as Tar
import           Data.Aeson                   (decode)
import           Data.Text                    as TextS
import qualified Data.Text.Encoding           as TextS
import qualified Data.Text.IO                 as TextIO
import qualified Data.ByteString.Lazy         as BS (ByteString, fromStrict) 
import           Network.HTTP.Client          as Net  hiding (Proxy)
import           Network.HTTP.Client.MultipartFormData
import           Network.HTTP.Types           (Status(..))
import           Servant.Client
import qualified Servant.Client.Streaming     as S
import           Servant.Types.SourceT        (SourceT, foreach)

import           Network.Ipfs.Api.Api         (_cat, _ls, _get, _refs, _refsLocal, _swarmPeers, _swarmConnect,
                                              _swarmDisconnect, _swarmFilterAdd, _swarmFilters,
                                              _swarmFilterRm, _bitswapStat, _bitswapWL, _bitswapLedger,
                                              _bitswapReprovide, _cidBases, _cidCodecs, _cidHashes, _cidBase32,
                                              _cidFormat, _blockGet, _objectDiff, _blockStat, _dagGet,
                                              _dagResolve, _configGet, _configSet, _objectData,
                                              _objectNew, _objectGetLinks, _objectAddLink, _objectRmLink,
                                              _objectGet, _objectStat, _pinAdd, _pinRemove,_bootstrapList, 
                                              _bootstrapAdd, _bootstrapRM, _statsBw, _statsRepo, _version,
                                              _id, _idPeer, _dns, _pubsubLs, _pubsubPeers, _logLs, _logLevel,
                                              _repoVersion, _repoFsck, _keyGen, _keyList, _keyRm, _keyRename,
                                              _filesChcid, _filesCp, _filesFlush, _filesLs, _filesMkdir, _filesMv, _filesRead, _filesRm, _filesStat, _shutdown, BlockObj, DagPutObj,
                                              ObjectObj, ObjectLinksObj)

import           Network.Ipfs.Api.Multipart   (AddObj)
import           Network.Ipfs.Api.Stream      (_ping, _dhtFindPeer, _dhtFindProvs, _dhtGet, _dhtProvide,
                                              _dhtQuery, _logTail, _repoGc, _repoVerify)


call :: ClientM a -> IO (Either ServantError a)
call func = do 
    manager' <- newManager defaultManagerSettings
    runClientM func (mkClientEnv manager' (BaseUrl Http "localhost" 5001 "/api/v0"))

streamCall :: Show a => S.ClientM (SourceT IO a) -> IO()
streamCall func = do 
    manager' <- newManager defaultManagerSettings
    S.withClientM func (S.mkClientEnv manager' (BaseUrl Http "localhost" 5001 "/api/v0")) $ \e -> case e of
        Left err -> putStrLn $ "Error: " ++ show err
        Right rs -> foreach fail print rs

multipartCall ::  Text -> Text -> IO (Net.Response BS.ByteString)
multipartCall uri filePath = do
    reqManager <- newManager defaultManagerSettings
    req <- parseRequest $ TextS.unpack uri
    resp <- flip httpLbs reqManager =<< formDataBody form req
    return (resp)
    
    where form = [ partFileSource "file" $ TextS.unpack filePath ]

cat :: Text -> IO ()
cat hash = do 
    res <- call $ _cat hash
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> TextIO.putStr v

add :: Text -> IO()
add filePath = do 
    responseVal <- multipartCall (TextS.pack "http://localhost:5001/api/v0/add") filePath 
    print (decode (Net.responseBody responseVal)  :: Maybe AddObj)
    
ls :: Text -> IO ()
ls hash = do 
    res <- call $ _ls hash
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v

get :: Text -> IO ()
get hash = do 
    res <- call $ _get hash
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v ->  do  Tar.unpack "getResponseDirectory" . Tar.read $ BS.fromStrict $ TextS.encodeUtf8 v
                        print "The content has been stored in getResponseDirectory."

refs :: Text -> IO ()
refs hash = do 
    res <- call $ _refs hash
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v  

refsLocal :: IO ()
refsLocal = do 
    res <- call _refsLocal
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v
 
swarmPeers :: IO ()
swarmPeers = do 
    res <- call _swarmPeers
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v        

-- | peerId has to be of the format - /ipfs/id        
swarmConnect :: Text -> IO ()
swarmConnect peerId = do 
    res <- call $ _swarmConnect (Just peerId)  
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v

-- | peerId has to be of the format - /ipfs/id        
swarmDisconnect :: Text -> IO ()
swarmDisconnect peerId = do 
    res <- call $ _swarmDisconnect (Just peerId)  
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v

swarmFilters :: IO ()
swarmFilters = do 
    res <- call _swarmFilters
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v

-- | peerId has to be of the format - /ip4/{IP addr of peer}/ipcidr/{ip network prefix}       
swarmFilterAdd :: Text -> IO ()
swarmFilterAdd filterParam = do 
    res <- call $ _swarmFilterAdd (Just filterParam)  
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v

swarmFilterRm :: Text -> IO ()
swarmFilterRm filterParam = do 
    res <- call $ _swarmFilterRm (Just filterParam)  
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v  

bitswapStat :: IO ()
bitswapStat = do 
    res <- call _bitswapStat
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v
        
bitswapWL :: IO ()
bitswapWL = do 
    res <- call _bitswapWL
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v    
        
bitswapLedger :: Text -> IO ()
bitswapLedger peerId = do 
    res <- call $ _bitswapLedger peerId
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v
        
bitswapReprovide :: IO ()
bitswapReprovide = do 
    res <- call $ _bitswapReprovide
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> TextIO.putStr v 

cidBases :: IO ()
cidBases = do 
    res <- call $ _cidBases
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v 
        
cidCodecs :: IO ()
cidCodecs = do 
    res <- call $ _cidCodecs
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v 
        
cidHashes :: IO ()
cidHashes = do 
    res <- call $ _cidHashes
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v 

cidBase32 :: Text -> IO ()
cidBase32 hash = do 
    res <- call $ _cidBase32 hash
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v
                
cidFormat :: Text-> IO ()
cidFormat hash = do 
    res <- call $ _cidFormat hash
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v  
        
blockGet :: Text -> IO ()
blockGet key = do 
    res <- call $ _blockGet key
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> TextIO.putStr v
        
blockPut :: Text -> IO()
blockPut filePath = do 
    responseVal <- multipartCall (TextS.pack "http://localhost:5001/api/v0/block/put") filePath 
    print (decode (Net.responseBody responseVal)  :: Maybe BlockObj)
        
blockStat :: Text -> IO ()
blockStat key = do 
    res <- call $ _blockStat key
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v

dagGet :: Text -> IO ()
dagGet ref = do 
    res <- call $ _dagGet ref
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v ->  TextIO.putStr v 

dagResolve :: Text -> IO ()
dagResolve ref = do 
    res <- call $ _dagResolve ref
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v 

dagPut :: Text -> IO()
dagPut filePath = do 
    responseVal <- multipartCall (TextS.pack "http://localhost:5001/api/v0/dag/put") filePath 
    print (decode (Net.responseBody responseVal)  :: Maybe DagPutObj)

configGet :: Text -> IO ()
configGet key = do 
    res <- call $ _configGet key
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v

configSet :: Text -> Text -> IO ()
configSet key value = do 
    res <- call $ _configSet key $ Just value
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v 

configReplace :: Text -> IO()
configReplace filePath = do 
    responseVal <- multipartCall (TextS.pack "http://localhost:5001/api/v0/config/replace") filePath 
    case statusCode $ Net.responseStatus responseVal of 
        200 -> putStrLn "Config File Replaced Successfully with status code - "
        _   -> putStrLn $ "Error occured with status code - "
    print $ statusCode $ Net.responseStatus responseVal
                
objectData :: Text -> IO ()
objectData key = do 
    res <- call $ _objectData key
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> TextIO.putStr v

objectNew :: IO ()
objectNew = do 
    res <- call _objectNew
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v
 
objectGetLinks :: Text -> IO ()
objectGetLinks key = do 
    res <- call $ _objectGetLinks key
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v

objectAddLink ::  Text -> Text -> Text -> IO ()
objectAddLink hash name key = do 
    res <- call $ _objectAddLink hash (Just name) (Just key)
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v

objectRmLink :: Text -> Text -> IO ()
objectRmLink key name = do 
    res <- call $ _objectRmLink key (Just name)
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v

objectAppendData :: Text -> Text -> IO()
objectAppendData key filePath = do 
    responseVal <- multipartCall ( ( TextS.pack "http://localhost:5001/api/v0/object/patch/append-data?arg=" ) <> key) filePath 
    print (decode ( Net.responseBody responseVal)  :: Maybe ObjectLinksObj)        

objectSetData :: Text -> Text -> IO()
objectSetData key filePath = do 
    responseVal <- multipartCall ( ( TextS.pack "http://localhost:5001/api/v0/object/patch/set-data?arg=" ) <>key) filePath 
    print (decode ( Net.responseBody responseVal)  :: Maybe ObjectLinksObj)        
        
objectGet :: Text -> IO ()
objectGet key = do 
    res <- call $ _objectGet key
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v 

objectDiff :: Text -> Text -> IO ()
objectDiff firstKey secondKey = do 
    res <- call $ _objectDiff firstKey (Just secondKey)
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v 

objectPut :: Text -> IO()
objectPut filePath = do 
    responseVal <- multipartCall (TextS.pack "http://localhost:5001/api/v0/object/put") filePath 
    print (decode ( Net.responseBody responseVal)  :: Maybe ObjectObj)        

objectStat :: Text -> IO ()
objectStat key = do 
    res <- call $ _objectStat key
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v 

pinAdd :: Text -> IO ()
pinAdd pinPath = do 
    res <- call $ _pinAdd pinPath
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v 

pinRemove :: Text -> IO ()
pinRemove pinPath = do 
    res <- call $ _pinRemove pinPath
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v

bootstrapAdd :: Text -> IO ()
bootstrapAdd peerId = do 
    res <- call $ _bootstrapAdd (Just peerId)
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v

bootstrapList :: IO ()
bootstrapList = do 
    res <- call $ _bootstrapList
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v

bootstrapRM :: Text -> IO ()
bootstrapRM peerId = do 
    res <- call $ _bootstrapRM  (Just peerId)
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v

statsBw :: IO ()
statsBw = do 
    res <- call $ _statsBw  
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v

statsRepo :: IO ()
statsRepo = do 
    res <- call $ _statsRepo  
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v

version :: IO ()
version = do 
    res <- call $ _version  
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v

id :: IO ()
id = do 
    res <- call $ _id  
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v

idPeer :: Text -> IO ()
idPeer peerId = do 
    res <- call $ _idPeer peerId  
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v

dns :: Text -> IO ()
dns name = do 
    res <- call $ _dns name  
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v

ping :: Text -> IO ()
ping cid = streamCall $ _ping cid  

dhtFindPeer :: Text -> IO ()
dhtFindPeer peerid = streamCall $ _dhtFindPeer peerid  

dhtFindProvs :: Text -> IO ()
dhtFindProvs cid = streamCall $ _dhtFindProvs cid  

dhtGet :: Text -> IO ()
dhtGet cid = streamCall $ _dhtGet cid  

dhtProvide :: Text -> IO ()
dhtProvide cid = streamCall $ _dhtProvide cid 

dhtQuery ::  Text -> IO ()
dhtQuery peerId = streamCall $ _dhtQuery peerId

pubsubLs :: IO ()
pubsubLs = do 
    res <- call _pubsubLs  
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v

pubsubPeers :: IO ()
pubsubPeers = do 
    res <- call _pubsubPeers
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v

logLs :: IO ()
logLs = do 
    res <- call _logLs
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v

logLevel :: Text -> Text -> IO ()
logLevel subsystem level = do 
    res <- call $ _logLevel subsystem $ Just level
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v

logTail :: IO ()
logTail = streamCall _logTail

repoVersion :: IO ()
repoVersion = do 
    res <- call _repoVersion
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v

repoFsck :: IO ()
repoFsck = do 
    res <- call _repoFsck
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v

repoGc :: IO ()
repoGc = streamCall _repoGc

repoVerify :: IO ()
repoVerify = streamCall _repoVerify

keyList :: IO ()
keyList = do 
    res <- call _keyList
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v

keyGen :: Text -> Text -> IO ()
keyGen name keyType = do 
    res <- call $ _keyGen name (Just keyType)
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v

keyRename :: Text -> Text -> IO ()
keyRename was now  = do 
    res <- call $ _keyRename was $ Just now 
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v        

keyRm :: Text -> IO ()
keyRm name  = do 
    res <- call $ _keyRm name 
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v

filesChcidVer :: Text -> Int -> IO ()
filesChcidVer mfsPath cidVersion = do 
    res <- call $ _filesChcid (Just mfsPath) (Just cidVersion)
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right _ -> putStrLn "The directory's cid version has been changed."

filesCp :: Text -> Text -> IO ()
filesCp src dest  = do 
    res <- call $ _filesCp (Just src) (Just dest)
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right _ -> putStrLn "The object has been copied to the specified destination"

filesFlush ::Text -> IO ()
filesFlush mfsPath = do 
    res <- call $ _filesFlush $ Just mfsPath 
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v

filesLs :: Text -> IO ()
filesLs mfsPath  = do 
    res <- call $ _filesLs $ Just mfsPath 
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v

filesMkdir :: Text -> IO ()
filesMkdir mfsPath  = do 
    res <- call $ _filesMkdir $ Just mfsPath 
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right _ -> putStrLn "The Directory has been created on the specified path."

filesMv :: Text -> Text -> IO ()
filesMv src dest  = do 
    res <- call $ _filesMv (Just src) (Just dest)
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right _ -> putStrLn "The object has been moved to the specified destination"

filesRead :: Text -> IO ()
filesRead mfsPath  = do 
    res <- call $ _filesRead $ Just mfsPath 
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> TextIO.putStr v

filesStat :: Text -> IO ()
filesStat mfsPath  = do 
    res <- call $ _filesStat $ Just mfsPath 
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right v -> print v

filesRm :: Text -> IO ()
filesRm mfsPath  = do 
    res <- call $ _filesRm (Just mfsPath) (Just True)  
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right _ -> putStrLn "The object has been removed."

filesWrite :: Text -> Text -> Bool -> IO()
filesWrite mfsPath filePath toTruncate = do 
    responseVal <- multipartCall ((TextS.pack "http://localhost:5001/api/v0/files/write?arg=") 
        <> mfsPath <> (TextS.pack "&create=true") <>  (TextS.pack "&truncate=") <> (TextS.pack $ show toTruncate) ) filePath 
    case statusCode $ Net.responseStatus responseVal of 
        200 -> putStrLn "Config File Replaced Successfully with status code - "
        _   -> putStrLn $ "Error occured with status code - "
    print $ statusCode $ Net.responseStatus responseVal    

shutdown :: IO ()
shutdown = do 
    res <- call $ _shutdown   
    case res of
        Left err -> putStrLn $ "Error: " ++ show err
        Right _ -> putStrLn "The daemon has been shutdown, your welcome."
