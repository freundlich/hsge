{-# LANGUAGE NoImplicitPrelude #-}

module SGE.Input (
	KeyboardPtr,
	KeyCallback,
	KeyboardKey(..),
	KeyState(..),
	RawKeyboardPtr,
	withKeyCallback
)

#include <sgec/input/keyboard/device.h>
#include <sgec/input/keyboard/key_code.h>
#include <sgec/input/keyboard/key_state.h>

where

import Control.Exception ( bracket )

import Control.Monad ( (>>=) )

import Data.Eq ( Eq )

import Data.Function ( ($) )

import Data.List ( (++) )

import Data.Maybe ( Maybe )

import Foreign ( ForeignPtr, newForeignPtr_, withForeignPtr )

import Foreign.C ( CInt(..) )

import Foreign.Marshal.Utils ( maybePeek )

import Foreign.Ptr ( FunPtr, Ptr, nullPtr )

import Prelude ( Enum (fromEnum, toEnum), error )

import qualified SGE.Signal ( ConnectionPtr, RawConnectionPtr, destroy )

import SGE.Utils ( failMaybe, fromCInt )

import System.IO ( IO )

import Text.Show ( Show, show )

data KeyboardStruct

type RawKeyboardPtr = Ptr KeyboardStruct

type KeyboardPtr = ForeignPtr KeyboardStruct

type RawKeyCallback = FunPtr (CInt -> CInt -> Ptr () -> IO ())

type WrappedKeyCallback = CInt -> CInt -> Ptr () -> IO ()

{#enum sgec_input_keyboard_key_code as KeyboardKey {underscoreToCase} with prefix = "sgec_input_keyboard_key_code" add prefix = "KeyboardKey" deriving (Eq, Show)#}

{#enum sgec_input_keyboard_key_state as KeyState {underscoreToCase} with prefix = "sgec_input_keyboard_key_state" add prefix = "KeyState" deriving (Eq, Show)#}

foreign import ccall unsafe "sgec_input_keyboard_device_connect_key_callback" sgeConnectKey :: RawKeyboardPtr -> RawKeyCallback -> Ptr () -> IO (SGE.Signal.RawConnectionPtr)

foreign import ccall unsafe "wrapper" wrapKeyCallback :: WrappedKeyCallback -> IO RawKeyCallback

type KeyCallback = KeyboardKey -> KeyState -> IO ()

-- TODO: We need to free the wrapped key callback
connectKeyCallback :: KeyboardPtr -> KeyCallback -> IO (Maybe SGE.Signal.ConnectionPtr)
connectKeyCallback keyboard callback =
	withForeignPtr keyboard $ \kp ->
	(wrapKeyCallback $ \key -> \value -> \_ -> callback (toEnum $ fromCInt key) (toEnum $ fromCInt value))
	>>= \wrappedCallback -> sgeConnectKey kp wrappedCallback nullPtr
	>>= maybePeek newForeignPtr_

connectKeyCallbackExn :: KeyboardPtr -> KeyCallback -> IO SGE.Signal.ConnectionPtr
connectKeyCallbackExn keyboard callback =
	failMaybe "connect key callback" (connectKeyCallback keyboard callback)

withKeyCallback :: KeyboardPtr -> KeyCallback -> (() -> IO a) -> IO a
withKeyCallback keyboard callback function =
	bracket (connectKeyCallbackExn keyboard callback) SGE.Signal.destroy (\_ -> function ())