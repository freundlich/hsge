module SGE.Sprite (
       Object(..),
       draw
)

#include <sgec/sprite/object.h>

where

import Control.Monad ( return )
import Data.Eq ( Eq )
import Data.Function ( ($) )
import Data.List ( map )
import Data.Maybe ( Maybe, fromMaybe )
import Foreign ( Storable(..) )
import Foreign.C ( CFloat, CInt, CUInt(..), CSize(..) )
import Foreign.ForeignPtr ( withForeignPtr )
import Foreign.ForeignPtr.Unsafe ( unsafeForeignPtrToPtr )
import Foreign.Marshal.Array ( withArrayLen )
import Foreign.Ptr ( Ptr )
import Prelude ( Float )
import System.IO ( IO )

import SGE.Dim ( Dim(..), dimW, dimH )
import SGE.Image ( RGBA, convertRGBA )
import SGE.Pos ( Pos, posX, posY )
import SGE.Renderer ( ContextPtr, DevicePtr, RawContextPtr, RawDevicePtr )
import SGE.Texture ( PartPtr, RawPartPtr )
import SGE.Utils ( toCFloat, toCInt, toCUInt, toCSize )

data RawObject = RawObject {
     raw_tex :: RawPartPtr,
     raw_x :: CInt,
     raw_y :: CInt,
     raw_w :: CInt,
     raw_h :: CInt,
     raw_rotation :: CFloat,
     raw_color :: CUInt
} deriving(Eq)

data Object = Object {
     pos :: Pos,
     dim :: Dim,
     rotation :: Float,
     texture :: PartPtr,
     color :: RGBA
} deriving(Eq)

instance Storable RawObject where
         sizeOf _ = (#size struct sgec_sprite_object)
         alignment _ = (#alignment struct sgec_sprite_object)
         peek ptr = do
              tex <- (#peek struct sgec_sprite_object, texture) ptr
              x <- (#peek struct sgec_sprite_object, pos_x) ptr
              y <- (#peek struct sgec_sprite_object, pos_y) ptr
              w <- (#peek struct sgec_sprite_object, width) ptr
              h <- (#peek struct sgec_sprite_object, height) ptr
              r <- (#peek struct sgec_sprite_object, rotation) ptr
              c <- (#peek struct sgec_sprite_object, color) ptr
              return $ RawObject { raw_x = x, raw_y = y, raw_w = w, raw_h = h, raw_rotation = r, raw_tex = tex, raw_color = c }
         poke ptr (RawObject tex x y w h r c) = do
              (#poke struct sgec_sprite_object, texture) ptr tex
              (#poke struct sgec_sprite_object, pos_x) ptr x
              (#poke struct sgec_sprite_object, pos_y) ptr y
              (#poke struct sgec_sprite_object, width) ptr w
              (#poke struct sgec_sprite_object, height) ptr h
              (#poke struct sgec_sprite_object, rotation) ptr r
              (#poke struct sgec_sprite_object, color) ptr c

foreign import ccall unsafe "sgec_sprite_draw" sgeSpriteDraw :: RawDevicePtr -> RawContextPtr -> CUInt -> CUInt -> Ptr RawObject -> CSize -> IO ()

draw :: DevicePtr -> ContextPtr -> Maybe Dim -> [Object] -> IO ()
draw device context d sprites =
     let realDim = fromMaybe (Dim (0,0)) d in
     let toRawObject obj = RawObject {
         raw_tex = unsafeForeignPtrToPtr $ texture obj,
         raw_x = toCInt $ posX $ pos obj,
         raw_y = toCInt $ posY $ pos obj,
         raw_w = toCInt $ dimW $ dim obj,
         raw_h = toCInt $ dimH $ dim obj,
         raw_rotation = toCFloat $ rotation obj,
         raw_color = convertRGBA $ color obj
     } in
       withArrayLen (map toRawObject sprites) $
       \length -> \array -> withForeignPtr device $
       \dp -> withForeignPtr context $
       \cp -> sgeSpriteDraw dp cp (toCUInt (dimW realDim)) (toCUInt (dimH realDim)) array $ toCSize length
