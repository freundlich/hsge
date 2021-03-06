module SGE.Utils (
       failMaybe,
       failResult,
       failResultIO,
       failWithMessage,
       fromCInt,
       fromCLong,
       fromCUInt,
       fromCSize,
       maybeString,
       toCFloat,
       toCInt,
       toCUChar,
       toCUInt,
       toCSize,
       toResult
)

where

import Control.Monad ( liftM, return )
import Data.Function ( ($) )
import Data.Int ( Int )
import Data.Maybe ( Maybe(Just, Nothing) )
import Data.Word ( Word8 )
import Data.String ( String )
import Foreign.C ( CFloat, CInt, CLong, CSize, CUChar, CUInt )
import Foreign.C.String ( CString, withCString )
import Foreign.Ptr ( nullPtr )
import Prelude ( Enum(toEnum), Float, Integral, fromIntegral, realToFrac )
import System.IO ( IO )
import System.IO.Error ( ioError, userError )

import SGE.Result ( Result(..) )

failWithMessage :: String -> IO a
failWithMessage message =
                ioError $ userError $ message

failMaybe :: String -> IO (Maybe a) -> IO a
failMaybe message action = do
          val <- action
          case val of
               Just a -> return a
               Nothing -> failWithMessage message

failResult :: String -> IO Result -> IO ()
failResult message action = do
           val <- action
           case val of
                ResultOk -> return ()
                ResultError -> failWithMessage message

failResultIO :: String -> IO CInt -> IO ()
failResultIO message action =
             failResult message $ liftM toResult $ liftM fromCInt $ action

fromCInt :: Integral a => CInt -> a
fromCInt = fromIntegral

fromCLong :: Integral a => CLong -> a
fromCLong = fromIntegral

fromCUInt :: Integral a => CUInt -> a
fromCUInt = fromIntegral

fromCSize :: Integral a => CSize -> a
fromCSize = fromIntegral

toCUInt :: Integral a => a -> CUInt
toCUInt = fromIntegral

toCFloat :: Float -> CFloat
toCFloat = realToFrac

toCInt :: Integral a => a -> CInt
toCInt = fromIntegral

toCUChar :: Word8 -> CUChar
toCUChar = fromIntegral

toCSize :: Integral a => a -> CSize
toCSize = fromIntegral

toResult :: Int -> Result
toResult = toEnum

maybeString :: Maybe String -> (CString -> IO a) -> IO a
maybeString s f =
            case s of
                 Nothing -> f nullPtr
                 Just x -> withCString x f
