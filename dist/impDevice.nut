/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * Standard Squirrel code should include this first to use Electric Imp Squirrel
 * code written with math.abs(x), etc.
 */
if (!("math" in getroottable())) {
  // We are not on the Imp, so define math.
  math <- {
    function abs(x) { return ::abs(x); }
    function acos(x) { return ::acos(x); }
    function asin(x) { return ::asin(x); }
    function atan(x) { return ::atan(x); }
    function atan2(x, y) { return ::atan2(x, y); }
    function ceil(x) { return ::ceil(x); }
    function cos(x) { return ::cos(x); }
    function exp(x) { return ::exp(x); }
    function fabs(x) { return ::fabs(x); }
    function floor(x) { return ::floor(x); }
    function log(x) { return ::log(x); }
    function log10(x) { return ::log10(x); }
    function pow(x, y) { return ::pow(x, y); }
    function rand() { return ::rand(); }
    function sin(x) { return ::sin(x); }
    function sqrt(x) { return ::sqrt(x); }
    function tan(x) { return ::tan(x); }
  }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * A Buffer wraps a Squirrel blob and provides an API imitating the Node.js
 * Buffer class, especially where the slice method returns a view onto the
 * same underlying blob array instead of making a copy. The size of the
 * underlying Squirrel blob is fixed and can't be resized.
 */
class Buffer {
  blob_ = ::blob(0);
  offset_ = 0;
  len_ = 0;

  /**
   * Create a new Buffer based on the value.
   * @param {integer|Buffer|blob|array<integer>|string} value If value is an
   * integer, create a new underlying blob of the given size. If value is a
   * Buffer, copy its bytes into a new underlying blob of size value.len(). (If
   * you want a new Buffer without copying, use value.size().) If value is a
   * Squirrel blob, copy its bytes into a new underlying blob. (If you want a
   * new Buffer without copying the blob, use Buffer.from(value).) If value is a
   * byte array, copy into a new underlying blob. If value is a string, treat it
   * as "raw" and copy to a new underlying blob without UTF-8 encoding.
   * @param {string} encoding (optional) If value is a string, convert it to a
   * byte array as follows. If encoding is "raw" or omitted, copy value to a new
   * underlying blob without UTF-8 encoding. If encoding is "hex", value must be
   * a sequence of pairs of hexadecimal digits, so convert them to integers.
   * @throws string if the encoding is unrecognized or a hex string has invalid
   * characters (or is not a multiple of 2 in length).
   */
  constructor(value, encoding = "raw")
  {
    local valueType = typeof value;

    if (valueType == "blob") {
      // Copy.
      if (value.len() > 0) {
        // Copy the value blob. Set and restore its read/write pointer.
        local savePointer = value.tell();
        value.seek(0);
        blob_ = value.readblob(value.len());
        value.seek(savePointer);

        len_ = value.len();
      }
    }
    else if (valueType == "integer") {
      if (value > 0) {
        blob_ = ::blob(value);
        len_ = value;
      }
    }
    else if (valueType == "array") {
      // Assume the array has integer values.
      blob_ = ::blob(value.len());
      foreach (x in value)
        blob_.writen(x, 'b');

      len_ = value.len();
    }
    else if (valueType == "string") {
      if (encoding == "raw") {
        // Just copy the string. Don't UTF-8 decode.
        blob_ = ::blob(value.len());
        // Don't use writestring since Standard Squirrel doesn't have it.
        foreach (x in value)
          blob_.writen(x, 'b');

        len_ = value.len();
      }
      else if (encoding == "hex") {
        if (value.len() % 2 != 0)
          throw "Invalid hex value";
        len_ = value.len() / 2;
        blob_ = ::blob(len_);

        local iBlob = 0;
        for (local i = 0; i < value.len(); i += 2) {
          local hi = ::Buffer.fromHexChar(value[i]);
          local lo = ::Buffer.fromHexChar(value[i + 1]);
          if (hi < 0 || lo < 0)
            throw "Invalid hex value";

          blob_[iBlob++] = 16 * hi + lo;
        }
      }
      else
        throw "Unrecognized encoding";
    }
    else if (value instanceof ::Buffer) {
      if (value.len_ > 0) {
        // Copy only the bytes we needed from the value's blob.
        value.blob_.seek(value.offset_);
        blob_ = value.blob_.readblob(value.len_);

        len_ = value.len_;
      }
    }
    else
      throw "Unrecognized type";
  }

  /**
   * Get a new Buffer which wraps the given Squirrel blob, sharing its array.
   * @param {blob} blob The Squirrel blob to use for the new Buffer.
   * @param {integer} offset (optional) The index where the new Buffer will
   * start. If omitted, use 0.
   * @param {integer} len (optional) The number of bytes from the given blob
   * that this Buffer will share. If omitted, use blob.len() - offset.
   * @return {Buffer} A new Buffer.
   */
  static function from(blob, offset = 0, len = null)
  {
    if (len == null)
      len = blob.len() - offset;

    // TODO: Do a bounds check?
    // First create a Buffer with default values, then set the blob_ and len_.
    local result = Buffer(0);
    result.blob_ = blob;
    result.offset_ = offset;
    result.len_ = len;
    return result;
  }

  /**
   * Get the length of this Buffer.
   * @return {integer} The length.
   */
  function len() { return len_; }

  /**
   * Copy bytes from a region of this Buffer to a region in target even if the
   * target region overlaps this Buffer.
   * @param {Buffer|blob|array} target The Buffer or Squirrel blob or array of
   * integers to copy to.
   * @param {integer} targetStart (optional) The start index in target to copy
   * to. If omitted, use 0.
   * @param {integer} sourceStart (optional) The start index in this Buffer to
   * copy from. If omitted, use 0.
   * @param {integer} sourceEnd (optional) The end index in this Buffer to copy
   * from (not inclusive). If omitted, use len().
   * @return {integer} The number of bytes copied.
   */
  function copy(target, targetStart = 0, sourceStart = 0, sourceEnd = null)
  {
    if (sourceEnd == null)
      sourceEnd = len_;

    local nBytes = sourceEnd - sourceStart;

    // Get the index in the source and target blobs.
    local iSource = offset_ + sourceStart;
    local targetBlob;
    local iTarget;
    if (target instanceof ::Buffer) {
      targetBlob = target.blob_;
      iTarget = target.offset_ + targetStart;
    }
    else if (typeof target == "array") {
      // Special case. Just copy bytes to the array and return.
      iTarget = targetStart;
      local iEnd = offset_ + sourceEnd;
      while (iSource < iEnd)
        target[iTarget++] = blob_[iSource++];
      return nBytes;
    }
    else {
      targetBlob = target;
      iTarget = targetStart;
    }

    if (targetBlob == blob_) {
      // We are copying within the same blob.
      if (iTarget > iSource && iTarget < offset_ + sourceEnd)
        // Copying to the target will overwrite the source.
        throw "Buffer.copy: Overlapping copy is not supported yet";
    }

    if (iSource == 0 && sourceEnd == blob_.len()) {
      // We can use writeblob to copy the entire blob_.
      // Set and restore its read/write pointer.
      local savePointer = targetBlob.tell();
      targetBlob.seek(iTarget);
      targetBlob.writeblob(blob_);
      targetBlob.seek(savePointer);
    }
    else {
      // Don't use blob's readblob since it makes its own copy.
      // TODO: Does Squirrel have a memcpy?
      local iEnd = offset_ + sourceEnd;
      while (iSource < iEnd)
        targetBlob[iTarget++] = blob_[iSource++];
    }

    return nBytes;
  }

  /**
   * Get a new Buffer that references the same underlying blob array as the
   * original, but offset and cropped by the start and end indices. Note that
   * modifying the new Buffer slice will modify the original Buffer because the
   * allocated blob array portions of the two objects overlap.
   * @param {integer} start (optional) The index where the new Buffer will start.
   * If omitted, use 0.
   * @param {integer} end (optional) The index where the new Buffer will end
   * (not inclusive). If omitted, use len().
   */
  function slice(start = 0, end = null)
  {
    if (end == null)
      end = len_;

    if (start == 0 && end == len_)
      return this;

    // TODO: Do a bounds check?
    local result = ::Buffer.from(blob_);
    // Fix offset_ and len_.
    result.offset_ = offset_ + start;
    result.len_ = end - start;
    return result;
  }

  /**
   * Return a new Buffer which is the result of concatenating all the Buffer 
   * instances in the list together.
   * @param {Array<Buffer>} list An array of Buffer instances to concat. If the
   * list has no items, return a new zero-length Buffer.
   * @param {integer} (optional) totalLength The total length of the Buffer
   * instances in list when concatenated. If omitted, calculate the total
   * length, but this causes an additional loop to be executed, so it is faster
   * to provide the length explicitly if it is already known. If the total
   * length is zero, return a new zero-length Buffer.
   * @return {Buffer} A new Buffer.
   */
  static function concat(list, totalLength = null)
  {
    if (list.len() == 1)
      // A simple case.
      return ::Buffer(list[0]);
  
    if (totalLength == null) {
      totalLength = 0;
      foreach (buffer in list)
        totalLength += buffer.len();
    }

    local result = ::blob(totalLength);
    local offset = 0;
    foreach (buffer in list) {
      buffer.copy(result, offset);
      offset += buffer.len();
    }

    return ::Buffer.from(result);
  }

  /**
   * Get a string with the bytes in the blob array using the given encoding.
   * @param {string} encoding If encoding is "hex", return the hex
   * representation of the bytes in the blob array. If encoding is "raw",
   * return the bytes of the byte array as a raw str of the same length. (This
   * does not do any character encoding such as UTF-8.)
   * @return {string} The encoded string.
   */
  function toString(encoding)
  {
    if (encoding == "hex") {
      // TODO: Does Squirrel have a StringBuffer?
      local result = "";
      for (local i = 0; i < len_; ++i)
        result += ::format("%02x", get(i));

      return result;
    }
    else if (encoding == "raw") {
      // Don't use readstring since Standard Squirrel doesn't have it.
      local result = "";
      // TODO: Does Squirrel have a StringBuffer?
      for (local i = 0; i < len_; ++i)
        result += get(i).tochar();

      return result;
    }
    else
      throw "Unrecognized encoding";
  }

  /**
   * Return a copy of the bytes of the array as a Squirrel blob.
   * @return {blob} A new Squirrel blob with the copied bytes.
   */
  function toBlob()
  {
    if (len_ <= 0)
      return ::blob(0);

    blob_.seek(offset_);
    return blob_.readblob(len_);
  }

  /**
   * A utility function to convert the hex character to an integer from 0 to 15.
   * @param {integer} c The integer character.
   * @return (integer} The hex value, or -1 if x is not a hex character.
   */
  static function fromHexChar(c)
  {
    if (c >= '0' && c <= '9')
      return c - '0';
    else if (c >= 'A' && c <= 'F')
      return c - 'A' + 10;
    else if (c >= 'a' && c <= 'f')
      return c - 'a' + 10;
    else
      return -1;
  }

  /**
   * Get the value at the index.
   * @param {integer} i The zero-based index into the buffer array.
   * @return {integer} The value at the index.
   */
  function get(i) { return blob_[offset_ + i]; }

  /**
   * Set the value at the index.
   * @param {integer} i The zero-based index into the buffer array.
   * @param {integer} value The value to set.
   */
  function set(i, value) { blob_[offset_ + i] = value; }

  function _get(i)
  {
    // Note: In this class, we always reference globals with :: to avoid
    // invoking this _get metamethod.

    if (typeof i == "integer")
      // TODO: Do a bounds check?
      return blob_[offset_ + i];
    else
      throw "Unrecognized type";
  }

  function _set(i, value)
  {
    if (typeof i == "integer")
      // TODO: Do a bounds check?
      blob_[offset_ + i] = value;
    else
      throw "Unrecognized type";
  }

  function _nexti(previdx)
  {
    if (len_ <= 0)
      return null;
    else if (previdx == null)
      return 0;
    else if (previdx == len_ - 1)
      return null;
    else
      return previdx + 1;
  }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * A Blob holds an immutable byte array implemented as a Buffer. This should be
 * treated like a string which is a pointer to an immutable string. (It is OK to
 * pass a pointer to the string because the new owner can’t change the bytes of
 * the string.)  Instead you must call buf() to get the byte array which reminds
 * you that you should not change the contents.  Also remember that buf() can
 * return null.
 */
class Blob {
  buffer_ = null;

  /**
   * Create a new Blob which holds an immutable array of bytes.
   * @param {Blob|SignedBlob|Buffer|blob|array<integer>|string} value (optional)
   * If value is a Blob or SignedBlob, take another pointer to its Buffer
   * without copying. If value is a Buffer or Squirrel blob, optionally copy.
   * If value is a byte array, copy to create a new Buffer. If value is a string,
   * treat it as "raw" and copy to a byte array without UTF-8 encoding.  If
   * omitted, buf() will return null.
   * @param {bool} copy (optional) If true, copy the contents of value into a 
   * new Buffer. If value is a Squirrel blob, copy the entire array, ignoring
   * the location of its blob pointer given by value.tell().  If copy is false,
   * and value is a Buffer or Squirrel blob, just use it without copying. If
   * omitted, then copy the contents (unless value is already a Blob).
   * IMPORTANT: If copy is false, if you keep a pointer to the value then you
   * must treat the value as immutable and promise not to change it.
   */
  constructor(value = null, copy = true)
  {
    if (value == null)
      buffer_ = null;
    else if (value instanceof Blob)
      // Use the existing buffer. Don't need to check for copy.
      buffer_ = value.buffer_;
    else {
      if (copy)
        // We are copying, so just make another Buffer.
        buffer_ = Buffer(value);
      else {
        if (value instanceof Buffer)
          // We can use it as-is.
          buffer_ = value;
        else if (typeof value == "blob")
          buffer_ = Buffer.from(value);
        else
          // We need a Buffer, so copy.
          buffer_ = Buffer(value);
      }
    }
  }

  /**
   * Return the length of the immutable byte array.
   * @return {integer} The length of the array.  If buf() is null, return 0.
   */
  function size()
  {
    if (buffer_ != null)
      return buffer_.len();
    else
      return 0;
  }

  /**
   * Return the immutable byte array.  DO NOT change the contents of the buffer.
   * If you need to change it, make a copy.
   * @return {Buffer} The Buffer holding the immutable byte array, or null.
   */
  function buf() { return buffer_; }

  /**
   * Return true if the array is null, otherwise false.
   * @return {bool} True if the array is null.
   */
  function isNull() { return buffer_ == null; }

  /**
   * Return the hex representation of the bytes in the byte array.
   * @return {string} The hex string.
   */
  function toHex()
  {
    if (buffer_ == null)
      return "";
    else
      return buffer_.toString("hex");
  }

  /**
   * Return the bytes of the byte array as a raw str of the same length. This
   * does not do any character encoding such as UTF-8.
   * @return The buffer as a string, or "" if isNull().
   */
  function toRawStr()
  {
    if (buffer_ == null)
      return "";
    else
      return buffer_.toString("raw");
  }

  /**
   * Check if the value of this Blob equals the other blob.
   * @param {Blob} other The other Blob to check.
   * @return {bool} if this isNull and other isNull or if the bytes of this Blob
   * equal the bytes of the other.
   */
  function equals(other)
  {
    if (isNull())
      return other.isNull();
    else if (other.isNull())
      return false;
    else {
      if (buffer_.len() != other.buffer_.len())
        return false;

      // TODO: Does Squirrel have a native buffer compare?
      for (local i = 0; i < buffer_.len(); ++i) {
        if (buffer_.get(i) != other.buffer_.get(i))
          return false;
      }

      return true;
    }
  }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * A ChangeCounter keeps a target object whose change count is tracked by a
 * local change count.  You can set to a new target which updates the local
 * change count, and you can call checkChanged to check if the target (or one of
 * the target's targets) has been changed. The target object must have a method
 * getChangeCount.
 */
class ChangeCounter {
  target_ = null;
  changeCount_ = 0;

  /**
   * Create a new ChangeCounter to track the given target. If target is not null,
   * this sets the local change counter to target.getChangeCount().
   * @param {instance} target The target to track, as an object with the method
   * getChangeCount().
   */
  constructor(target)
  {
    target_ = target;
    changeCount_ = (target == null ? 0 : target.getChangeCount());
  }

  /**
   * Get the target object. If the target is changed, then checkChanged will
   * detect it.
   * @return {instance} The target, as an object with the method
   * getChangeCount().
   */
  function get() { return target_; }

  /**
   * Set the target to the given target. If target is not null, this sets the
   * local change counter to target.getChangeCount().
   * @param {instance} target The target to track, as an object with the method
   * getChangeCount().
   */
  function set(target)
  {
    target_ = target;
     changeCount_ = (target == null ? 0 : target.getChangeCount());
  }

  /**
   * If the target's change count is different than the local change count, then
   * update the local change count and return true. Otherwise return false,
   * meaning that the target has not changed. Also, if the target is null,
   * simply return false. This is useful since the target (or one of the
   * target's targets) may be changed and you need to find out.
   * @return {bool} True if the change count has been updated, false if not.
   */
  function checkChanged()
  {
    if (target_ == null)
      return false;

    local targetChangeCount = target_.getChangeCount();
    if (changeCount_ != targetChangeCount) {
      changeCount_ = targetChangeCount;
      return true;
    }
    else
      return false;
  }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * Crypto has static methods for basic cryptography operations.
 */
class Crypto {
  /**
   * Fill the value with random bytes. Note: If not on the Imp, you must seed
   * with srand().
   * @param {Buffer|blob} value Write the random bytes to this array from
   * startIndex to endIndex. If this is a Squirrel blob, it ignores the location
   * of the blob pointer given by value.tell() and does not update the blob
   * pointer.
   * @param startIndex (optional) The index of the first byte in value to set.
   * If omitted, start from index 0.
   * @param endIndex (optional) Set bytes in value up to endIndex - 1. If
   * omitted, set up to value.len() - 1.
   */
  static function generateRandomBytes(value, startIndex = 0, endIndex = null)
  {
    if (endIndex == null)
      endIndex = value.len();

    local valueIsBuffer = (value instanceof Buffer);
    for (local i = startIndex; i < endIndex; ++i) {
      local x = ((1.0 * math.rand() / RAND_MAX) * 256).tointeger();
      if (valueIsBuffer)
        // Use Buffer.set to avoid using the metamethod.
        value.set(i, x);
      else
        value[i] = x;
    }
  }

  /**
   * Get the Crunch object, creating it if necessary. (To save memory, we don't
   * want to create it until needed.)
   * @return {Crunch} The Crunch object.
   */
  static function getCrunch()
  {
    if (::Crypto_crunch_ == null)
      ::Crypto_crunch_ = Crunch();
    return ::Crypto_crunch_;
  }
}

Crypto_crunch_ <- null;
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * A DynamicBlobArray holds a Squirrel blob and provides methods to ensure a
 * minimum length, resizing if necessary.
 */
class DynamicBlobArray {
  array_ = null;        // blob

  /**
   * Create a new DynamicBlobArray with an initial length.
   * @param initialLength (optional) The initial length of the allocated array.
   * If omitted, use a default
   */
  constructor(initialLength = 16)
  {
    array_ = blob(initialLength);
  }

  /**
   * Ensure that the array has the minimal length, resizing it if necessary.
   * The new length of the array may be greater than the given length.
   * @param {integer} length The minimum length for the array.
   */
  function ensureLength(length)
  {
    // array_.len() is always the full length of the array.
    if (array_.len() >= length)
      return;

    // See if double is enough.
    local newLength = array_.len() * 2;
    if (length > newLength)
      // The needed length is much greater, so use it.
      newLength = length;

    // Instead of using resize, we manually copy to a new blob so that
    // array_.len() will be the full length.
    local newArray = blob(newLength);
    newArray.writeblob(array_);
    array_ = newArray;
  }

  /**
   * Copy the given buffer into this object's array, using ensureLength to make
   * sure there is enough room.
   * @param {Buffer} buffer A Buffer with the bytes to copy.
   * @param {integer} offset The offset in this object's array to copy to.
   * @return {integer} The new offset which is offset + buffer.length.
   */
  function copy(buffer, offset)
  {
    ensureLength(offset + buffer.len());
    buffer.copy(array_, offset);

    return offset + buffer.len();
  }

  /**
   * Ensure that the array has the minimal length. If necessary, reallocate the
   * array and shift existing data to the back of the new array. The new length
   * of the array may be greater than the given length.
   * @param {integer} length The minimum length for the array.
   */
  function ensureLengthFromBack(length)
  {
    // array_.len() is always the full length of the array.
    if (array_.len() >= length)
      return;

    // See if double is enough.
    local newLength = array_.len() * 2;
    if (length > newLength)
      // The needed length is much greater, so use it.
      newLength = length;

    local newArray = blob(newLength);
    // Copy to the back of newArray.
    newArray.seek(newArray.len() - array_.len());
    newArray.writeblob(array_);
    array_ = newArray;
  }

  /**
   * First call ensureLengthFromBack to make sure the bytearray has
   * offsetFromBack bytes, then copy the given buffer into this object's array
   * starting offsetFromBack bytes from the back of the array.
   * @param {Buffer} buffer A Buffer with the bytes to copy.
   * @param {integer} offset The offset from the back of the array to start
   * copying.
   */
  function copyFromBack(buffer, offsetFromBack)
  {
    ensureLengthFromBack(offsetFromBack);
    buffer.copy(array_, array_.len() - offsetFromBack);
  }

  /**
   * Wrap this object's array in a Buffer slice starting lengthFromBack from the
   * back of this object's array and make a Blob. Finally, set this object's
   * array to null to prevent further use.
   * @param {integer} lengthFromBack The final length of the allocated array.
   * @return {Blob} A new NDN Blob with the bytes from the array.
   */
  function finishFromBack(lengthFromBack)
  {
    local result = Blob
      (Buffer.from(array_, array_.len() - lengthFromBack), false);
    array_ = null;
    return result;
  }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * NdnCommon has static NDN utility methods and constants.
 */
class NdnCommon {
  /**
   * The practical limit of the size of a network-layer packet. If a packet is
   * larger than this, the library or application MAY drop it. This constant is
   * defined in this low-level class so that internal code can use it, but
   * applications should use the static API method
   * Face.getMaxNdnPacketSize() which is equivalent.
   */
  MAX_NDN_PACKET_SIZE = 8800;

  /**
   * Get the current time in seconds.
   * @return {integer} The current time in seconds since 1/1/1970 UTC.
   */
  static function getNowSeconds() { return time(); }

  /**
   * Compute the HMAC with SHA-256 of data, as defined in
   * http://tools.ietf.org/html/rfc2104#section-2 .
   * @param {Buffer} key The key.
   * @param {Buffer} data The input byte buffer.
   * @return {Buffer} The HMAC result.
   */
  static function computeHmacWithSha256(key, data)
  {
    if (haveCrypto_)
      return Buffer.from(crypto.hmacsha256(data.toBlob(), key.toBlob()));
    else if (haveHttpHash_)
      return Buffer.from(http.hash.hmacsha256(data.toBlob(), key.toBlob()));
    else {
      // For testing, compute a simple int hash and repeat it.
      local hash = 0;
      for (local i = 0; i < key.len(); ++i)
        hash += 37 * key.get(i);
      for (local i = 0; i < data.len(); ++i)
        hash += 37 * data.get(i);

      local result = blob(32);
      // Write the 4-byte integer 8 times.
      for (local i = 0; i < 8; ++i)
        result.writen(hash, 'i');
      return Buffer.from(result);
    }
  }

  haveCrypto_ = "crypto" in getroottable();
  haveHttpHash_ = "http" in getroottable() && "hash" in ::http;
}

/**
 * Make a global function to log a message to the console which works with
 * standard Squirrel or on the Imp.
 * @param {string} message The message to log.
 */
if (!("consoleLog" in getroottable())) {
  consoleLog <- function(message) {
    if ("server" in getroottable())
      server.log(message);
    else
      print(message); print("\n");
  }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * A SignedBlob extends Blob to keep the offsets of a signed portion (e.g., the
 * bytes of Data packet). This inherits from Blob, including Blob.size and
 * Blob.buf.
 */
class SignedBlob extends Blob {
  signedBuffer_ = null;
  signedPortionBeginOffset_ = 0;
  signedPortionEndOffset_ = 0;

  /**
   * Create a new SignedBlob using the given optional value and offsets.
   * @param {Blob|SignedBlob|Buffer|blob|array<integer>|string} value (optional)
   * If value is a Blob or SignedBlob, take another pointer to its Buffer
   * without copying. If value is a Buffer or Squirrel blob, optionally copy.
   * If value is a byte array, copy to create a new Buffer. If value is a string,
   * treat it as "raw" and copy to a byte array without UTF-8 encoding.  If
   * omitted, buf() will return null.
   * @param {integer} signedPortionBeginOffset (optional) The offset in the
   * encoding of the beginning of the signed portion. If omitted, set to 0.
   * @param {integer} signedPortionEndOffset (optional) The offset in the
   * encoding of the end of the signed portion. If omitted, set to 0.
   */
  constructor
    (value = null, signedPortionBeginOffset = null,
     signedPortionEndOffset = null)
  {
    // Call the base constructor.
    base.constructor(value);

    if (buffer_ == null) {
      // Offsets are already 0 by default.
    }
    else if (value instanceof SignedBlob) {
      // Copy the SignedBlob, allowing override for offsets.
      signedPortionBeginOffset_ = signedPortionBeginOffset == null ?
        value.signedPortionBeginOffset_ : signedPortionBeginOffset;
      signedPortionEndOffset_ = signedPortionEndOffset == null ?
        value.signedPortionEndOffset_ : signedPortionEndOffset;
    }
    else {
      if (signedPortionBeginOffset != null)
        signedPortionBeginOffset_ = signedPortionBeginOffset;
      if (signedPortionEndOffset != null)
        signedPortionEndOffset_ = signedPortionEndOffset;
    }

    if (buffer_ != null)
      signedBuffer_ = buffer_.slice
        (signedPortionBeginOffset_, signedPortionEndOffset_);
  }

  /**
   * Return the length of the signed portion of the immutable byte array.
   * @return {integer} The length of the signed portion. If signedBuf() is null,
   * return 0.
   */
  function signedSize()
  {
    if (signedBuffer_ != null)
      return signedBuffer_.len();
    else
      return 0;
  }

  /**
   * Return a the signed portion of the immutable byte array.
   * @return {Buffer} A Buffer which is the signed portion. If the array is
   * null, return null.
   */
  function signedBuf() { return signedBuffer_; }

  /**
   * Return the offset in the array of the beginning of the signed portion.
   * @return {integer} The offset in the array.
   */
  function getSignedPortionBeginOffset() { return signedPortionBeginOffset_; }

  /**
   * Return the offset in the array of the end of the signed portion.
   * @return {integer} The offset in the array.
   */
  function getSignedPortionEndOffset() { return signedPortionEndOffset_; }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * A NameComponentType specifies the recognized types of a name component.
 */
enum NameComponentType {
  IMPLICIT_SHA256_DIGEST = 1,
  GENERIC = 8
}

/**
 * A NameComponent holds a read-only name component value.
 */
class NameComponent {
  value_ = null;
  type_ = NameComponentType.GENERIC;

  /**
   * Create a new GENERIC NameComponent using the given value.
   * (To create an ImplicitSha256Digest component, use fromImplicitSha256Digest.)
   * @param {NameComponent|Blob|blob|Buffer|Array<integer>|string} value
   * (optional) If the value is a NameComponent or Blob, use its value directly,
   * otherwise use the value according to the Blob constructor. If the value is
   * null or omitted, create a zero-length component.
   * @throws string if value is a Blob and it isNull.
   */
  constructor(value = null)
  {
    if (value instanceof NameComponent) {
      // The copy constructor.
      value_ = value.value_;
      type_ = value.type_;
      return;
    }

    if (value == null)
      value_ = Blob([]);
    else if (value instanceof Blob)
      value_ = value;
    else
      // Blob will make a copy if needed.
      value_ = Blob(value);
  }

  /**
   * Get the component value.
   * @return {Blob} The component value.
   */
  function getValue() { return value_; }

  /**
   * Convert this component value to a string by escaping characters according
   * to the NDN URI Scheme.
   * This also adds "..." to a value with zero or more ".".
   * This adds a type code prefix as needed, such as "sha256digest=".
   * @return {string} The escaped string.
   */
  function toEscapedString()
  {
    if (type_ == NameComponentType.IMPLICIT_SHA256_DIGEST)
      return "sha256digest=" + value_.toHex();
    else
      return Name.toEscapedString(value_.buf());
  }

  // TODO isSegment.
  // TODO isSegmentOffset.
  // TODO isVersion.
  // TODO isTimestamp.
  // TODO isSequenceNumber.

  /**
   * Check if this component is a generic component.
   * @return {bool} True if this is an generic component.
   */
  function isGeneric()
  {
    return type_ == NameComponentType.GENERIC;
  }

  /**
   * Check if this component is an ImplicitSha256Digest component.
   * @return {bool} True if this is an ImplicitSha256Digest component.
   */
  function isImplicitSha256Digest()
  {
    return type_ == NameComponentType.IMPLICIT_SHA256_DIGEST;
  }

  /**
   * Interpret this name component as a network-ordered number and return an
   * integer.
   * @return {integer} The integer number.
   */
  function toNumber()
  {
    local buf = value_.buf();
    local result = 0;
    for (local i = 0; i < buf.len(); ++i) {
      result = result << 8;
      result += buf.get(i);
    }
  
    return result;
  }

  // TODO toNumberWithMarker.
  // TODO toSegment.
  // TODO toSegmentOffset.
  // TODO toVersion.
  // TODO toTimestamp.
  // TODO toSequenceNumber.

  /**
   * Create a component whose value is the nonNegativeInteger encoding of the
   * number.
   * @param {integer} number
   * @return {NameComponent}
   */
  static function fromNumber(number)
  {
    local encoder = TlvEncoder(8);
    encoder.writeNonNegativeInteger(number);
    return NameComponent(encoder.finish());
  };

  // TODO fromNumberWithMarker.
  // TODO fromSegment.
  // TODO fromSegmentOffset.
  // TODO fromVersion.
  // TODO fromTimestamp.
  // TODO fromSequenceNumber.

  /**
   * Create a component of type ImplicitSha256DigestComponent, so that
   * isImplicitSha256Digest() is true.
   * @param {Blob|blob|Buffer|Array<integer>} digest The SHA-256 digest value.
   * @return {NameComponent} The new NameComponent.
   * @throws string If the digest length is not 32 bytes.
   */
  static function fromImplicitSha256Digest(digest)
  {
    local digestBlob = digest instanceof Blob ? digest : Blob(digest, true);
    if (digestBlob.size() != 32)
      throw 
        "Name.Component.fromImplicitSha256Digest: The digest length must be 32 bytes";

    local result = NameComponent(digestBlob);
    result.type_ = NameComponentType.IMPLICIT_SHA256_DIGEST;
    return result;
  }

  // TODO getSuccessor.

  /**
   * Check if this is the same component as other.
   * @param {NameComponent} other The other Component to compare with.
   * @return {bool} True if the components are equal, otherwise false.
   */
  function equals(other)
  {
    return value_.equals(other.value_) && type_ == other.type_;
  }

  /**
   * Compare this to the other Component using NDN canonical ordering.
   * @param {NameComponent} other The other Component to compare with.
   * @return {integer} 0 if they compare equal, -1 if this comes before other in
   * the canonical ordering, or 1 if this comes after other in the canonical
   * ordering.
   * @see http://named-data.net/doc/0.2/technical/CanonicalOrder.html
   */
  function compare(other)
  {
    if (type_ < other.type_)
      return -1;
    if (type_ > other.type_)
      return 1;

    local buffer1 = value_.buf();
    local buffer2 = other.value_.buf();
    if (buffer1.len() < buffer2.len())
        return -1;
    if (buffer1.len() > buffer2.len())
        return 1;

    // The components are equal length. Just do a byte compare.
    // TODO: Does Squirrel have a native buffer compare?
    for (local i = 0; i < buffer1.len(); ++i) {
      // Use Buffer.get to avoid using the metamethod.
      if (buffer1.get(i) < buffer2.get(i))
        return -1;
      if (buffer1.get(i) > buffer2.get(i))
        return 1;
    }

    return 0;
  }
}

/**
 * A Name holds an array of NameComponent and represents an NDN name.
 */
class Name {
  components_ = null;
  changeCount_ = 0;

  constructor(components = null)
  {
    local componentsType = typeof components;

    if (componentsType == "string") {
      components_ = [];
      set(components);
    }
    else if (components instanceof Name)
      // Don't need to deep-copy Component elements because they are read-only.
      components_ = components.components_.slice(0);
    else if (componentsType == "array")
      // Don't need to deep-copy Component elements because they are read-only.
      components_ = components.slice(0);
    else if (components == null)
      components_ = [];
    else
      throw "Name constructor: Unrecognized components type";
  }

  /**
   * Parse the uri according to the NDN URI Scheme and set the name with the
   * components.
   * @param {string} uri The URI string.
   */
  function set(uri)
  {
    clear();

    uri = strip(uri);
    if (uri.len() <= 0)
      return;

    local iColon = uri.find(":");
    if (iColon != null) {
      // Make sure the colon came before a "/".
      local iFirstSlash = uri.find("/");
      if (iFirstSlash == null || iColon < iFirstSlash)
        // Omit the leading protocol such as ndn:
        uri = strip(uri.slice(iColon + 1));
    }

    if (uri[0] == '/') {
      if (uri.len() >= 2 && uri[1] == '/') {
        // Strip the authority following "//".
        local iAfterAuthority = uri.find("/", 2);
        if (iAfterAuthority == null)
          // Unusual case: there was only an authority.
          return;
        else
          uri = strip(uri.slice(iAfterAuthority + 1));
      }
      else
        uri = strip(uri.slice(1));
    }

    // Note that Squirrel split does not return an empty entry between "//".
    local array = split(uri, "/");

    // Unescape the components.
    local sha256digestPrefix = "sha256digest=";
    for (local i = 0; i < array.len(); ++i) {
      local component;
      if (array[i].len() > sha256digestPrefix.len() &&
          array[i].slice(0, sha256digestPrefix.len()) == sha256digestPrefix) {
        local hexString = strip(array[i].slice(sha256digestPrefix.len()));
        component = NameComponent.fromImplicitSha256Digest
          (Blob(Buffer(hexString, "hex"), false));
      }
      else
        component = NameComponent(Name.fromEscapedString(array[i]));

      if (component.getValue().isNull()) {
        // Ignore the illegal componenent.  This also gets rid of a trailing '/'.
        array.remove(i);
        --i;
        continue;
      }
      else
        array[i] = component;
    }

    components_ = array;
    ++changeCount_;
  }

  /**
   * Append a GENERIC component to this Name.
   * @param {Name|NameComponent|Blob|Buffer|blob|Array<integer>|string} component
   * If component is a Name, append all its components. If component is a
   * NameComponent, append it as is. Otherwise use the value according to the 
   * Blob constructor. If component is a string, convert it directly as in the
   * Blob constructor (don't unescape it).
   * @return {Name} This Name object to allow chaining calls to add.
   */
  function append(component)
  {
    if (component instanceof Name) {
      local components;
      if (component == this)
        // Special case: We need to create a copy.
        components = components_.slice(0);
      else
        components = component.components_;

      for (local i = 0; i < components.len(); ++i)
        components_.append(components[i]);
    }
    else if (component instanceof NameComponent)
      // The Component is immutable, so use it as is.
      components_.append(component);
    else
      // Just use the NameComponent constructor.
      components_.append(NameComponent(component));

    ++changeCount_;
    return this;
  }

  /**
   * Clear all the components.
   */
  function clear()
  {
    components_ = [];
    ++changeCount_;
  }

  /**
   * Return the escaped name string according to NDN URI Scheme.
   * @param {bool} includeScheme (optional) If true, include the "ndn:" scheme
   * in the URI, e.g. "ndn:/example/name". If false, just return the path, e.g.
   * "/example/name". If omitted, then just return the path which is the default
   * case where toUri() is used for display.
   * @return {string} The URI string.
   */
  function toUri(includeScheme = false)
  {
    if (this.size() == 0)
      return includeScheme ? "ndn:/" : "/";

    local result = includeScheme ? "ndn:" : "";

    for (local i = 0; i < size(); ++i)
      result += "/"+ components_[i].toEscapedString();

    return result;
  }

  function _tostring() { return toUri(); }

  // TODO: appendSegment.
  // TODO: appendSegmentOffset.
  // TODO: appendVersion.
  // TODO: appendTimestamp.
  // TODO: appendSequenceNumber.

  /**
   * Append a component of type ImplicitSha256DigestComponent, so that
   * isImplicitSha256Digest() is true.
   * @param {Blob|blob|Buffer|Array<integer>} digest The SHA-256 digest value.
   * @return This name so that you can chain calls to append.
   * @throws string If the digest length is not 32 bytes.
   */
  function appendImplicitSha256Digest(digest)
  {
    return this.append(NameComponent.fromImplicitSha256Digest(digest));
  }

  /**
   * Get a new name, constructed as a subset of components.
   * @param {integer} iStartComponent The index if the first component to get.
   * If iStartComponent is -N then return return components starting from
   * name.size() - N.
   * @param {integer} (optional) nComponents The number of components starting 
   * at iStartComponent. If omitted or greater than the size of this name, get
   * until the end of the name.
   * @return {Name} A new name.
   */
  function getSubName(iStartComponent, nComponents = null)
  {
    if (iStartComponent < 0)
      iStartComponent = components_.len() - (-iStartComponent);

    if (nComponents == null)
      nComponents = components_.len() - iStartComponent;

    local result = Name();

    local iEnd = iStartComponent + nComponents;
    for (local i = iStartComponent; i < iEnd && i < components_.len(); ++i)
      result.components_.append(components_[i]);

    return result;
  }

  /**
   * Return a new Name with the first nComponents components of this Name.
   * @param {integer} nComponents The number of prefix components.  If
   * nComponents is -N then return the prefix up to name.size() - N. For example
   * getPrefix(-1) returns the name without the final component.
   * @return {Name} A new name.
   */
  function getPrefix(nComponents)
  {
    if (nComponents < 0)
      return getSubName(0, components_.len() + nComponents);
    else
      return getSubName(0, nComponents);
  }

  /**
   * Return the number of name components.
   * @return {integer}
   */
  function size() { return components_.len(); }

  /**
   * Get a NameComponent by index number.
   * @param {integer} i The index of the component, starting from 0. However,
   * if i is negative, return the component at size() - (-i).
   * @return {NameComponent} The name component at the index.
   */
  function get(i)
  {
    if (i >= 0)
      return components_[i];
    else
      // Negative index.
      return components_[components_.len() - (-i)];
  }

  /**
   * Encode this Name for a particular wire format.
   * @param {WireFormat} wireFormat (optional) A WireFormat object used to
   * encode this object. If null or omitted, use WireFormat.getDefaultWireFormat().
   * @return {Blob} The encoded buffer in a Blob object.
   */
  function wireEncode(wireFormat = null)
  {
    if (wireFormat == null)
        // Don't use a default argument since getDefaultWireFormat can change.
        wireFormat = WireFormat.getDefaultWireFormat();

    return wireFormat.encodeName(this);
  }

  /**
   * Decode the input using a particular wire format and update this Name.
   * @param {Blob|Buffer} input The buffer with the bytes to decode.
   * @param {WireFormat} wireFormat (optional) A WireFormat object used to
   * decode this object. If null or omitted, use WireFormat.getDefaultWireFormat().
   */
  function wireDecode(input, wireFormat = null)
  {
    if (wireFormat == null)
        // Don't use a default argument since getDefaultWireFormat can change.
        wireFormat = WireFormat.getDefaultWireFormat();

    if (input instanceof Blob)
      wireFormat.decodeName(this, input.buf(), false);
    else
      wireFormat.decodeName(this, input, true);
  }

  /**
   * Check if this name has the same component count and components as the given
   * name.
   * @param {Name} The Name to check.
   * @return {bool} True if the names are equal, otherwise false.
   */
  function equals(name)
  {
    if (components_.len() != name.components_.len())
      return false;

    // Start from the last component because they are more likely to differ.
    for (local i = components_.len() - 1; i >= 0; --i) {
      if (!components_[i].equals(name.components_[i]))
        return false;
    }

    return true;
  }

  /**
   * Compare this to the other Name using NDN canonical ordering.  If the first
   * components of each name are not equal, this returns -1 if the first comes
   * before the second using the NDN canonical ordering for name components, or
   * 1 if it comes after. If they are equal, this compares the second components
   * of each name, etc.  If both names are the same up to the size of the
   * shorter name, this returns -1 if the first name is shorter than the second
   * or 1 if it is longer. For example, std::sort gives:
   * /a/b/d /a/b/cc /c /c/a /bb .  This is intuitive because all names with the
   * prefix /a are next to each other. But it may be also be counter-intuitive
   * because /c comes before /bb according to NDN canonical ordering since it is
   * shorter.
   * The first form of compare is simply compare(other). The second form is
   * compare(iStartComponent, nComponents, other [, iOtherStartComponent] [, nOtherComponents])
   * which is equivalent to
   * self.getSubName(iStartComponent, nComponents).compare
   * (other.getSubName(iOtherStartComponent, nOtherComponents)) .
   * @param {integer} iStartComponent The index if the first component of this
   * name to get. If iStartComponent is -N then compare components starting from
   * name.size() - N.
   * @param {integer} nComponents The number of components starting at
   * iStartComponent. If greater than the size of this name, compare until the end
   * of the name.
   * @param {Name} other The other Name to compare with.
   * @param {integer} iOtherStartComponent (optional) The index if the first
   * component of the other name to compare. If iOtherStartComponent is -N then
   * compare components starting from other.size() - N. If omitted, compare
   * starting from index 0.
   * @param {integer} nOtherComponents (optional) The number of components
   * starting at iOtherStartComponent. If omitted or greater than the size of
   * this name, compare until the end of the name.
   * @return {integer} 0 If they compare equal, -1 if self comes before other in
   * the canonical ordering, or 1 if self comes after other in the canonical
   * ordering.
   * @see http://named-data.net/doc/0.2/technical/CanonicalOrder.html
   */
  function compare
    (iStartComponent, nComponents = null, other = null,
     iOtherStartComponent = null, nOtherComponents = null)
  {
    if (iStartComponent instanceof Name) {
      // compare(other)
      other = iStartComponent;
      iStartComponent = 0;
      nComponents = size();
    }

    if (iOtherStartComponent == null)
      iOtherStartComponent = 0;
    if (nOtherComponents == null)
      nOtherComponents = other.size();

    if (iStartComponent < 0)
      iStartComponent = size() - (-iStartComponent);
    if (iOtherStartComponent < 0)
      iOtherStartComponent = other.size() - (-iOtherStartComponent);

    if (nComponents > size() - iStartComponent)
      nComponents = size() - iStartComponent;
    if (nOtherComponents > other.size() - iOtherStartComponent)
      nOtherComponents = other.size() - iOtherStartComponent;

    local count = nComponents < nOtherComponents ? nComponents : nOtherComponents;
    for (local i = 0; i < count; ++i) {
      local comparison = components_[iStartComponent + i].compare
        (other.components_[iOtherStartComponent + i]);
      if (comparison == 0)
        // The components at this index are equal, so check the next components.
        continue;

      // Otherwise, the result is based on the components at this index.
      return comparison;
    }

    // The components up to min(this.size(), other.size()) are equal, so the
    // shorter name is less.
    if (nComponents < nOtherComponents)
      return -1;
    else if (nComponents > nOtherComponents)
      return 1;
    else
      return 0;
  }

  /**
   * Return value as an escaped string according to NDN URI Scheme.
   * This does not add a type code prefix such as "sha256digest=".
   * @param {Buffer} value The value to escape.
   * @return {string} The escaped string.
   */
  static function toEscapedString(value)
  {
    // TODO: Does Squirrel have a StringBuffer?
    local result = "";
    local gotNonDot = false;
    for (local i = 0; i < value.len(); ++i) {
      // Use Buffer.get to avoid using the metamethod.
      if (value.get(i) != 0x2e) {
        gotNonDot = true;
        break;
      }
    }

    if (!gotNonDot) {
      // Special case for a component of zero or more periods. Add 3 periods.
      result = "...";
      for (local i = 0; i < value.len(); ++i)
        result += ".";
    }
    else {
      for (local i = 0; i < value.len(); ++i) {
        local x = value.get(i);
        // Check for 0-9, A-Z, a-z, (+), (-), (.), (_)
        if (x >= 0x30 && x <= 0x39 || x >= 0x41 && x <= 0x5a ||
            x >= 0x61 && x <= 0x7a || x == 0x2b || x == 0x2d ||
            x == 0x2e || x == 0x5f)
          result += x.tochar();
        else
          result += "%" + ::format("%02X", x);
      }
    }
  
    return result;
  }

  /**
   * Make a blob value by decoding the escapedString according to NDN URI 
   * Scheme. If escapedString is "", "." or ".." then return an isNull() Blob,
   * which means to skip the component in the name.
   * This does not check for a type code prefix such as "sha256digest=".
   * @param {string} escapedString The escaped string to decode.
   * @return {Blob} The unescaped Blob value. If the escapedString is not a
   * valid escaped component, then the Blob isNull().
   */
  static function fromEscapedString(escapedString)
  {
    local value = Name.unescape_(strip(escapedString));

    // Check for all dots.
    local gotNonDot = false;
    for (local i = 0; i < value.len(); ++i) {
      // Use Buffer.get to avoid using the metamethod.
      if (value.get(i) != '.') {
        gotNonDot = true;
        break;
      }
    }

    if (!gotNonDot) {
      // Special case for value of only periods.
      if (value.len() <= 2)
        // Zero, one or two periods is illegal.  Ignore this componenent to be
        //   consistent with the C implementation.
        return Blob();
      else
        // Remove 3 periods.
        return Blob(value.slice(3), false);
    }
    else
      return Blob(value, false);
  };

  /**
   * Return a copy of str, converting each escaped "%XX" to the char value.
   * @param {string} str The escaped string.
   * return {Buffer} The unescaped string as a Buffer.
   */
  static function unescape_(str)
  {
    local result = blob(str.len());

    for (local i = 0; i < str.len(); ++i) {
      if (str[i] == '%' && i + 2 < str.len()) {
        local hi = Buffer.fromHexChar(str[i + 1]);
        local lo = Buffer.fromHexChar(str[i + 2]);

        if (hi < 0 || lo < 0) {
          // Invalid hex characters, so just keep the escaped string.
          result.writen(str[i], 'b');
          result.writen(str[i + 1], 'b');
          result.writen(str[i + 2], 'b');
        }
        else
          result.writen(16 * hi + lo, 'b');

        // Skip ahead past the escaped value.
        i += 2;
      }
      else
        // Just copy through.
        result.writen(str[i], 'b');
    }

    return Buffer.from(result, 0, result.tell());
  }

  // TODO: getSuccessor

  /**
   * Return true if the N components of this name are the same as the first N
   * components of the given name.
   * @param {Name} name The name to check.
   * @return {bool} true if this matches the given name. This always returns
   * true if this name is empty.
   */
  function match(name)
  {
    local i_name = components_;
    local o_name = name.components_;

    // This name is longer than the name we are checking it against.
    if (i_name.len() > o_name.len())
      return false;

    // Check if at least one of given components doesn't match. Check from last
    // to first since the last components are more likely to differ.
    for (local i = i_name.len() - 1; i >= 0; --i) {
      if (!i_name[i].equals(o_name[i]))
        return false;
    }

    return true;
  }

  /**
   * Return true if the N components of this name are the same as the first N
   * components of the given name.
   * @param {Name} name The name to check.
   * @return {bool} true if this matches the given name. This always returns
   * true if this name is empty.
   */
  function isPrefixOf(name) { return match(name); }

  /**
   * Get the change count, which is incremented each time this object is changed.
   * @return {integer} The change count.
   */
  function getChangeCount() { return changeCount_; }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * A KeyLocatorType specifies the key locator type in a KeyLocator object.
 */
enum KeyLocatorType {
  KEYNAME = 1,
  KEY_LOCATOR_DIGEST =  2
}

/**
 * The KeyLocator class represents an NDN KeyLocator which is used in a
 * Sha256WithRsaSignature and Interest selectors.
 */
class KeyLocator {
  type_ = null;
  keyName_ = null;
  keyData_ = null;
  changeCount_ = 0;

  /**
   * Create a new KeyLocator.
   * @param {KeyLocator} keyLocator (optional) If keyLocator is another
   * KeyLocator object, copy its values. Otherwise, set all fields to defaut
   * values.
   */
  constructor(keyLocator = null)
  {
    if (keyLocator instanceof KeyLocator) {
      // The copy constructor.
      type_ = keyLocator.type_;
      keyName_ = ChangeCounter(Name(keyLocator.getKeyName()));
      keyData_ = keyLocator.keyData_;
    }
    else {
      type_ = null;
      keyName_ = ChangeCounter(Name());
      keyData_ = Blob();
    }
  }

  /**
   * Get the key locator type. If KeyLocatorType.KEYNAME, you may also call
   * getKeyName().  If KeyLocatorType.KEY_LOCATOR_DIGEST, you may also call
   * getKeyData() to get the digest.
   * @return {integer} The key locator type as a KeyLocatorType enum value,
   * or null if not specified.
   */
  function getType() { return type_; }

  /**
   * Get the key name. This is meaningful if getType() is KeyLocatorType.KEYNAME.
   * @return {Name} The key name. If not specified, the Name is empty.
   */
  function getKeyName() { return keyName_.get(); }

  /**
   * Get the key data. If getType() is KeyLocatorType.KEY_LOCATOR_DIGEST, this is
   * the digest bytes.
   * @return {Blob} The key data, or an isNull Blob if not specified.
   */
  function getKeyData() { return keyData_; }

  /**
   * Set the key locator type.  If KeyLocatorType.KEYNAME, you must also
   * setKeyName().  If KeyLocatorType.KEY_LOCATOR_DIGEST, you must also
   * setKeyData() to the digest.
   * @param {integer} type The key locator type as a KeyLocatorType enum value.
   * If null, the type is unspecified.
   */
  function setType(type)
  {
    type_ = type;
    ++changeCount_;
  }

  /**
   * Set key name to a copy of the given Name.  This is the name if getType()
   * is KeyLocatorType.KEYNAME.
   * @param {Name} name The key name which is copied.
   */
  function setKeyName(name)
  {
    keyName_.set(name instanceof Name ? Name(name) : Name());
    ++changeCount_;
  }

  /**
   * Set the key data to the given value. This is the digest bytes if getType()
   * is KeyLocatorType.KEY_LOCATOR_DIGEST.
   * @param {Blob} keyData A Blob with the key data bytes.
   */
  function setKeyData(keyData)
  {
    keyData_ = keyData instanceof Blob ? keyData : Blob(keyData);
    ++changeCount_;
  }

  /**
   * Clear the keyData and set the type to not specified.
   */
  function clear()
  {
    type_ = null;
    keyName_.set(Name());
    keyData_ = Blob();
    ++changeCount_;
  }

  /**
   * Check if this key locator has the same values as the given key locator.
   * @param {KeyLocator} other The other key locator to check.
   * @return {bool} true if the key locators are equal, otherwise false.
   */
  function equals(other)
{
    if (type_ != other.type_)
      return false;

    if (type_ == KeyLocatorType.KEYNAME) {
      if (!getKeyName().equals(other.getKeyName()))
        return false;
    }
    else if (type_ == KeyLocatorType.KEY_LOCATOR_DIGEST) {
      if (!getKeyData().equals(other.getKeyData()))
        return false;
    }

    return true;
  }

  /**
   * If the signature is a type that has a KeyLocator (so that,
   * getFromSignature will succeed), return true.
   * Note: This is a static method of KeyLocator instead of a method of
   * Signature so that the Signature base class does not need to be overloaded
   * with all the different kinds of information that various signature
   * algorithms may use.
   * @param {Signature} signature An object of a subclass of Signature.
   * @return {bool} True if the signature is a type that has a KeyLocator,
   * otherwise false.
   */
  static function canGetFromSignature(signature)
  {
    return signature instanceof Sha256WithRsaSignature ||
           signature instanceof HmacWithSha256Signature;
  }

  /**
   * If the signature is a type that has a KeyLocator, then return it. Otherwise
   * throw an error.
   * @param {Signature} signature An object of a subclass of Signature.
   * @return {KeyLocator} The signature's KeyLocator. It is an error if
   * signature doesn't have a KeyLocator.
   */
  static function getFromSignature(signature)
  {
    if (signature instanceof Sha256WithRsaSignature ||
        signature instanceof HmacWithSha256Signature)
      return signature.getKeyLocator();
    else
      throw
        "KeyLocator.getFromSignature: Signature type does not have a KeyLocator";
  }

  /**
   * Get the change count, which is incremented each time this object (or a
   * child object) is changed.
   * @return {integer} The change count.
   */
  function getChangeCount()
  {
    // Make sure each of the checkChanged is called.
    local changed = keyName_.checkChanged();
    if (changed)
      // A child object has changed, so update the change count.
      ++changeCount_;

    return changeCount_;
  }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * An ExcludeType specifies the type of an ExcludeEntry.
 */
enum ExcludeType {
  COMPONENT, ANY
}

/**
 * An ExcludeEntry holds an ExcludeType, and if it is a COMPONENT, it holds
 * the component value.
 */
class ExcludeEntry {
  type_ = 0;
  component_ = null;

  /**
   * Create a new Exclude.Entry.
   * @param {NameComponent|Blob|Buffer|blob|Array<integer>|string} (optional) If
   * value is omitted or null, create an ExcludeEntry of type ExcludeType.ANY.
   * Otherwise creat an ExcludeEntry of type ExcludeType.COMPONENT with the value.
   * If the value is a NameComponent or Blob, use its value directly, otherwise
   * use the value according to the Blob constructor.
   */
  constructor(value = null)
  {
    if (value == null)
      type_ = ExcludeType.ANY;
    else {
      type_ = ExcludeType.COMPONENT;
      component_ = value instanceof NameComponent ? value : NameComponent(value);
    }
  }

  /**
   * Get the type of this entry.
   * @return {integer} The Exclude type as an ExcludeType enum value.
   */
  function getType() { return type_; }

  /**
   * Get the component value for this entry (if it is of type ExcludeType.COMPONENT).
   * @return {NameComponent} The component value, or null if this entry is not
   * of type ExcludeType.COMPONENT.
   */
  function getComponent() { return component_; }
}

/**
 * The Exclude class is used by Interest and holds an array of ExcludeEntry to
 * represent the fields of an NDN Exclude selector.
 */
class Exclude {
  entries_ = null;
  changeCount_ = 0;

  /**
   * Create a new Exclude.
   * @param {Exclude} exclude (optional) If exclude is another Exclude
   * object, copy its values. Otherwise, set all fields to defaut values.
   */
  constructor(exclude = null)
  {
    if (exclude instanceof Exclude)
      // The copy constructor.
      entries_ = exclude.entries_.slice(0);
    else
      entries_ = [];
  }

  /**
   * Get the number of entries.
   * @return {integer} The number of entries.
   */
  function size() { return entries_.len(); }

  /**
   * Get the entry at the given index.
   * @param {integer} i The index of the entry, starting from 0.
   * @return {ExcludeEntry} The entry at the index.
   */
  function get(i) { return entries_[i]; }

  /**
   * Append a new entry of type Exclude.Type.ANY.
   * @return This Exclude so that you can chain calls to append.
   */
  function appendAny()
  {
    entries_.append(ExcludeEntry());
    ++changeCount_;
    return this;
  }

  /**
   * Append a new entry of type ExcludeType.COMPONENT with the give component.
   * @param component {NameComponent|Blob|Buffer|blob|Array<integer>|string} The
   * component value for the entry. If component is a NameComponent or Blob, use
   * its value directly, otherwise use the value according to the Blob
   * constructor.
   * @return This Exclude so that you can chain calls to append.
   */
  function appendComponent(component)
  {
    entries_.append(ExcludeEntry(component));
    ++changeCount_;
    return this;
  }

  /**
   * Clear all the entries.
   */
  function clear()
  {
    ++changeCount_;
    entries_ = [];
  }

  /**
   * Return a string with elements separated by "," and Exclude.ANY shown as "*".
   * @return {string} The URI string.
   */
  function toUri()
  {
    if (entries_.len() == 0)
      return "";

    local result = "";
    for (local i = 0; i < entries_.len(); ++i) {
      if (i > 0)
        result += ",";

      if (entries_[i].getType() == ExcludeType.ANY)
        result += "*";
      else
        result += entries_[i].getComponent().toEscapedString();
    }

    return result;
  }

  // TODO: matches.

  /**
   * Get the change count, which is incremented each time this object is changed.
   * @return {integer} The change count.
   */
  function getChangeCount() { return changeCount_; }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * The Interest class represents an NDN Interest packet.
 */
class Interest {
  name_ = null;
  maxSuffixComponents_ = null;
  minSuffixComponents_ = null;
  keyLocator_ = null;
  exclude_ = null;
  childSelector_ = null;
  mustBeFresh_ = true;
  interestLifetimeMilliseconds_ = null;
  nonce_ = null;
  getNonceChangeCount_ = 0;
  changeCount_ = 0;

  /**
   * Create a new Interest object from the optional value.
   * @param {Name|Interest} value (optional) If the value is a Name, make a copy 
   * and use it as the Interest packet's name. If the value is another Interest
   * object, copy its values. If the value is null or omitted, set all fields to
   * defaut values.
   */
  constructor(value = null)
  {
    if (value instanceof Interest) {
      // The copy constructor.
      local interest = value;
      name_ = ChangeCounter(Name(interest.getName()));
      maxSuffixComponents_ = interest.maxSuffixComponents_;
      minSuffixComponents_ = interest.minSuffixComponents_;
      keyLocator_ = ChangeCounter(KeyLocator(interest.getKeyLocator()));
      exclude_ = ChangeCounter(Exclude(interest.getExclude()));
      childSelector_ = interest.childSelector_;
      mustBeFresh_ = interest.mustBeFresh_;
      interestLifetimeMilliseconds_ = interest.interestLifetimeMilliseconds_;
      nonce_ = interest.nonce_;
    }
    else {
      name_ = ChangeCounter(value instanceof Name ? Name(value) : Name());
      minSuffixComponents_ = null;
      maxSuffixComponents_ = null;
      keyLocator_ = ChangeCounter(KeyLocator());
      exclude_ = ChangeCounter(Exclude());
      childSelector_ = null;
      mustBeFresh_ = true;
      interestLifetimeMilliseconds_ = null;
      nonce_ = Blob();
    }
  }

  // TODO matchesName.

  /**
   * Check if the given Data packet can satisfy this Interest. This method
   * considers the Name, MinSuffixComponents, MaxSuffixComponents,
   * PublisherPublicKeyLocator, and Exclude. It does not consider the
   * ChildSelector or MustBeFresh. This uses the given wireFormat to get the
   * Data packet encoding for the full Name.
   * @param {Data} data The Data packet to check.
   * @param {WireFormat} wireFormat (optional) A WireFormat object used to
   * encode the Data packet to get its full Name. If omitted, use
   * WireFormat.getDefaultWireFormat().
   * @return {bool} True if the given Data packet can satisfy this Interest.
   */
  function matchesData(data, wireFormat = null)
  {
    // Imitate ndn-cxx Interest::matchesData.
    local interestNameLength = getName().size();
    local dataName = data.getName();
    local fullNameLength = dataName.size() + 1;

    // Check MinSuffixComponents.
    local hasMinSuffixComponents = (getMinSuffixComponents() != null);
    local minSuffixComponents =
      hasMinSuffixComponents ? getMinSuffixComponents() : 0;
    if (!(interestNameLength + minSuffixComponents <= fullNameLength))
      return false;

    // Check MaxSuffixComponents.
    local hasMaxSuffixComponents = (getMaxSuffixComponents() != null);
    if (hasMaxSuffixComponents &&
        !(interestNameLength + getMaxSuffixComponents() >= fullNameLength))
      return false;

    // Check the prefix.
    if (interestNameLength == fullNameLength) {
      if (getName().get(-1).isImplicitSha256Digest()) {
        if (!getName().equals(data.getFullName(wireFormat)))
          return false;
      }
      else
        // The Interest Name is the same length as the Data full Name, but the
        //   last component isn't a digest so there's no possibility of matching.
        return false;
    }
    else {
      // The Interest Name should be a strict prefix of the Data full Name.
      if (!getName().isPrefixOf(dataName))
        return false;
    }

    // Check the Exclude.
    // The Exclude won't be violated if the Interest Name is the same as the
    //   Data full Name.
    if (getExclude().size() > 0 && fullNameLength > interestNameLength) {
      if (interestNameLength == fullNameLength - 1) {
        // The component to exclude is the digest.
        if (getExclude().matches
            (data.getFullName(wireFormat).get(interestNameLength)))
          return false;
      }
      else {
        // The component to exclude is not the digest.
        if (getExclude().matches(dataName.get(interestNameLength)))
          return false;
      }
    }

    // Check the KeyLocator.
    local publisherPublicKeyLocator = getKeyLocator();
    if (publisherPublicKeyLocator.getType()) {
      local signature = data.getSignature();
      if (!KeyLocator.canGetFromSignature(signature))
        // No KeyLocator in the Data packet.
        return false;
      if (!publisherPublicKeyLocator.equals
          (KeyLocator.getFromSignature(signature)))
        return false;
    }

    return true;
  }

  /**
   * Get the interest Name.
   * @return {Name} The name. The name size() may be 0 if not specified.
   */
  function getName() { return name_.get(); }

  /**
   * Get the min suffix components.
   * @return {integer} The min suffix components, or null if not specified.
   */
  function getMinSuffixComponents() { return minSuffixComponents_; }

  /**
   * Get the max suffix components.
   * @return {integer} The max suffix components, or null if not specified.
   */
  function getMaxSuffixComponents() { return maxSuffixComponents_; }

  /**
   * Get the interest key locator.
   * @return {KeyLocator} The key locator. If its getType() is null,
   * then the key locator is not specified.
   */
  function getKeyLocator() { return keyLocator_.get(); }

  /**
   * Get the exclude object.
   * @return {Exclude} The exclude object. If the exclude size() is zero, then
   * the exclude is not specified.
   */
  function getExclude() { return exclude_.get(); }

  /**
   * Get the child selector.
   * @return {integer} The child selector, or null if not specified.
   */
  function getChildSelector() { return childSelector_; }

  /**
   * Get the must be fresh flag. If not specified, the default is true.
   * @return {bool} The must be fresh flag.
   */
  function getMustBeFresh() { return mustBeFresh_; }

  /**
   * Return the nonce value from the incoming interest.  If you change any of
   * the fields in this Interest object, then the nonce value is cleared.
   * @return {Blob} The nonce. If not specified, the value isNull().
   */
  function getNonce()
  {
    if (getNonceChangeCount_ != getChangeCount()) {
      // The values have changed, so the existing nonce is invalidated.
      nonce_ = Blob();
      getNonceChangeCount_ = getChangeCount();
    }

    return nonce_;
  }

  /**
   * Get the interest lifetime.
   * @return {float} The interest lifetime in milliseconds, or null if not
   * specified.
   */
  function getInterestLifetimeMilliseconds() { return interestLifetimeMilliseconds_; }

  // TODO: hasLink.
  // TODO: getLink.
  // TODO: getLinkWireEncoding.
  // TODO: getSelectedDelegationIndex.
  // TODO: getIncomingFaceId.

  /**
   * Set the interest name.
   * Note: You can also call getName and change the name values directly.
   * @param {Name} name The interest name. This makes a copy of the name.
   * @return {Interest} This Interest so that you can chain calls to update
   * values.
   */
  function setName(name)
  {
    name_.set(name instanceof Name ? Name(name) : Name());
    ++changeCount_;
    return this;
  }

  /**
   * Set the min suffix components count.
   * @param {integer} minSuffixComponents The min suffix components count. If
   * not specified, set to null.
   * @return {Interest} This Interest so that you can chain calls to update
   * values.
   */
  function setMinSuffixComponents(minSuffixComponents)
  {
    minSuffixComponents_ = minSuffixComponents;
    ++changeCount_;
    return this;
  }

  /**
   * Set the max suffix components count.
   * @param {integer} maxSuffixComponents The max suffix components count. If not
   * specified, set to null.
   * @return {Interest} This Interest so that you can chain calls to update
   * values.
   */
  function setMaxSuffixComponents(maxSuffixComponents)
  {
    maxSuffixComponents_ = maxSuffixComponents;
    ++changeCount_;
    return this;
  }

  /**
   * Set this interest to use a copy of the given KeyLocator object.
   * Note: You can also call getKeyLocator and change the key locator directly.
   * @param {KeyLocator} keyLocator The KeyLocator object. This makes a copy of 
   * the object. If no key locator is specified, set to a new default
   * KeyLocator(), or to a KeyLocator with an unspecified type.
   * @return {Interest} This Interest so that you can chain calls to update
   * values.
   */
  function setKeyLocator(keyLocator)
  {
    keyLocator_.set
      (keyLocator instanceof KeyLocator ? KeyLocator(keyLocator) : KeyLocator());
    ++changeCount_;
    return this;
  }

  /**
   * Set this interest to use a copy of the given exclude object. Note: You can
   * also call getExclude and change the exclude entries directly.
   * @param {Exclude} exclude The Exclude object. This makes a copy of the object.
   * If no exclude is specified, set to a new default Exclude(), or to an Exclude
   * with size() 0.
   * @return {Interest} This Interest so that you can chain calls to update
   * values.
   */
  function setExclude(exclude)
  {
    exclude_.set(exclude instanceof Exclude ? Exclude(exclude) : Exclude());
    ++changeCount_;
    return this;
  }

  // TODO: setLinkWireEncoding.
  // TODO: unsetLink.
  // TODO: setSelectedDelegationIndex.

  /**
   * Set the child selector.
   * @param {integer} childSelector The child selector. If not specified, set to
   * null.
   * @return {Interest} This Interest so that you can chain calls to update
   * values.
   */
  function setChildSelector(childSelector)
  {
    childSelector_ = childSelector;
    ++changeCount_;
    return this;
  }

  /**
   * Set the MustBeFresh flag.
   * @param {bool} mustBeFresh True if the content must be fresh, otherwise
   * false. If you do not set this flag, the default value is true.
   * @return {Interest} This Interest so that you can chain calls to update
   * values.
   */
  function setMustBeFresh(mustBeFresh)
  {
    mustBeFresh_ = (mustBeFresh ? true : false);
    ++changeCount_;
    return this;
  }

  /**
   * Set the interest lifetime.
   * @param {float} interestLifetimeMilliseconds The interest lifetime in
   * milliseconds. If not specified, set to undefined.
   * @return {Interest} This Interest so that you can chain calls to update
   * values.
   */
  function setInterestLifetimeMilliseconds(interestLifetimeMilliseconds)
  {
    if (interestLifetimeMilliseconds == null || interestLifetimeMilliseconds < 0)
      interestLifetimeMilliseconds_ = null;
    else
      interestLifetimeMilliseconds_ = (typeof interestLifetimeMilliseconds == "float") ?
        interestLifetimeMilliseconds : interestLifetimeMilliseconds.tofloat();

    ++changeCount_;
    return this;
  }

  /**
   * @deprecated You should let the wire encoder generate a random nonce
   * internally before sending the interest.
   */
  function setNonce(nonce)
  {
    nonce_ = nonce instanceof Blob ? nonce : Blob(nonce, true);
    // Set getNonceChangeCount_ so that the next call to getNonce() won't clear
    // nonce_.
    ++changeCount_;
    getNonceChangeCount_ = getChangeCount();
    return this;
  }

  // TODO: toUri.

  /**
   * Encode this Interest for a particular wire format.
   * @param {WireFormat} wireFormat (optional) A WireFormat object used to
   * encode this object. If null or omitted, use WireFormat.getDefaultWireFormat().
   * @return {SignedBlob} The encoded buffer in a SignedBlob object.
   */
  function wireEncode(wireFormat = null)
  {
    if (wireFormat == null)
        // Don't use a default argument since getDefaultWireFormat can change.
        wireFormat = WireFormat.getDefaultWireFormat();

    local result = wireFormat.encodeInterest(this);
    // To save memory, don't cache the encoding.
    return SignedBlob
      (result.encoding, result.signedPortionBeginOffset,
       result.signedPortionEndOffset);
  }

  /**
   * Decode the input using a particular wire format and update this Interest.
   * @param {Blob|Buffer} input The buffer with the bytes to decode.
   * @param {WireFormat} wireFormat (optional) A WireFormat object used to
   * decode this object. If null or omitted, use WireFormat.getDefaultWireFormat().
   */
  function wireDecode(input, wireFormat = null)
  {
    if (wireFormat == null)
        // Don't use a default argument since getDefaultWireFormat can change.
        wireFormat = WireFormat.getDefaultWireFormat();

    if (input instanceof Blob)
      wireFormat.decodeInterest(this, input.buf(), false);
    else
      wireFormat.decodeInterest(this, input, true);
    // To save memory, don't cache the encoding.
  }

  /**
   * Update the bytes of the nonce with new random values. This ensures that the
   * new nonce value is different than the current one. If the current nonce is
   * not specified, this does nothing.
   */
  function refreshNonce()
  {
    local currentNonce = getNonce();
    if (currentNonce.size() == 0)
      return;

    local newNonce;
    while (true) {
      local buffer = Buffer(currentNonce.size());
      Crypto.generateRandomBytes(buffer);
      newNonce = Blob(buffer, false);
      if (!newNonce.equals(currentNonce))
        break;
    }

    nonce_ = newNonce;
    // Set getNonceChangeCount_ so that the next call to getNonce() won't clear
    // this.nonce_.
    ++changeCount_;
    getNonceChangeCount_ = getChangeCount();
  }

  // TODO: setLpPacket.

  /**
   * Get the change count, which is incremented each time this object (or a
   * child object) is changed.
   * @return {integer} The change count.
   */
  function getChangeCount()
  {
    // Make sure each of the checkChanged is called.
    local changed = name_.checkChanged();
    changed = keyLocator_.checkChanged() || changed;
    changed = exclude_.checkChanged() || changed;
    if (changed)
      // A child object has changed, so update the change count.
      ++changeCount_;

    return changeCount_;
  }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * An InterestFilter holds a Name prefix and optional regex match expression for
 * use in Face.setInterestFilter.
 */
class InterestFilter {
  prefix_ = null;
  regexFilter_ = null;
  regexFilterPattern_ = null;

  /**
   * Create an InterestFilter to match any Interest whose name starts with the
   * given prefix. If the optional regexFilter is provided then the remaining
   * components match the regexFilter regular expression as described in
   * doesMatch.
   * @param {InterestFilter|Name|string} prefix If prefix is another
   * InterestFilter copy its values. If prefix is a Name then this makes a copy
   * of the Name. Otherwise this creates a Name from the URI string.
   * @param {string} regexFilter (optional) The regular expression for matching
   * the remaining name components.
   */
  constructor(prefix, regexFilter = null)
  {
    if (prefix instanceof InterestFilter) {
      // The copy constructor.
      local interestFilter = prefix;
      prefix_ = Name(interestFilter.prefix_);
      regexFilter_ = interestFilter.regexFilter_;
      regexFilterPattern_ = interestFilter.regexFilterPattern_;
    }
    else {
      prefix_ = Name(prefix);
      if (regexFilter != null) {
/*      TODO: Support regex.
        regexFilter_ = regexFilter;
        regexFilterPattern_ = InterestFilter.makePattern(regexFilter);
*/
        throw "not supported";
      }
    }
  }
  
  /**
   * Check if the given name matches this filter. Match if name starts with this
   * filter's prefix. If this filter has the optional regexFilter then the
   * remaining components match the regexFilter regular expression.
   * For example, the following InterestFilter:
   *
   *    InterestFilter("/hello", "<world><>+")
   *
   * will match all Interests, whose name has the prefix `/hello` which is
   * followed by a component `world` and has at least one more component after it.
   * Examples:
   *
   *    /hello/world/!
   *    /hello/world/x/y/z
   *
   * Note that the regular expression will need to match all remaining components
   * (e.g., there are implicit heading `^` and trailing `$` symbols in the
   * regular expression).
   * @param {Name} name The name to check against this filter.
   * @return {bool} True if name matches this filter, otherwise false.
   */
  function doesMatch(name)
  {
    if (name.size() < prefix_.size())
      return false;

/*  TODO: Support regex. The constructor already rejected a regexFilter.
    if (hasRegexFilter()) {
      // Perform a prefix match and regular expression match for the remaining
      // components.
      if (!prefix_.match(name))
        return false;

      return null != NdnRegexMatcher.match
        (this.regexFilterPattern, name.getSubName(this.prefix.size()));
    }
    else
*/
      // Just perform a prefix match.
      return prefix_.match(name);
  }

  /**
   * Get the prefix given to the constructor.
   * @return {Name} The prefix Name which you should not modify.
   */
  function getPrefix() { return prefix_; }

  // TODO: hasRegexFilter
  // TODO: getRegexFilter
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * A ContentType specifies the content type in a MetaInfo object. If the
 * content type in the packet is not a recognized enum value, then we use
 * ContentType.OTHER_CODE and you can call MetaInfo.getOtherTypeCode(). We do
 * this to keep the recognized content type values independent of packet
 * encoding formats.
 */
enum ContentType {
  BLOB = 0,
  LINK = 1,
  KEY =  2,
  NACK = 3,
  OTHER_CODE = 0x7fff
}

/**
 * The MetaInfo class is used by Data and represents the fields of an NDN
 * MetaInfo. The MetaInfo type specifies the type of the content in the Data
 * packet (usually BLOB).
 */
class MetaInfo {
  type_ = 0;
  otherTypeCode_ = 0;
  freshnessPeriod_ = null;
  finalBlockId_ = null;
  changeCount_ = 0;

  /**
   * Create a new MetaInfo.
   * @param {MetaInfo} metaInfo (optional) If metaInfo is another MetaInfo
   * object, copy its values. Otherwise, set all fields to defaut values.
   */
  constructor(metaInfo = null)
  {
    if (metaInfo instanceof MetaInfo) {
      // The copy constructor.
      type_ = metaInfo.type_;
      otherTypeCode_ = metaInfo.otherTypeCode_;
      freshnessPeriod_ = metaInfo.freshnessPeriod_;
      finalBlockId_ = metaInfo.finalBlockId_;
    }
    else {
      type_ = ContentType.BLOB;
      otherTypeCode_ = -1;
      freshnessPeriod_ = null;
      finalBlockId_ = NameComponent();
    }
  }

  /**
   * Get the content type.
   * @return {integer} The content type as a ContentType enum value. If
   * this is ContentType.OTHER_CODE, then call getOtherTypeCode() to get the
   * unrecognized content type code.
   */
  function getType() { return type_; }

  /**
   * Get the content type code from the packet which is other than a recognized
   * ContentType enum value. This is only meaningful if getType() is
   * ContentType.OTHER_CODE.
   * @return {integer} The type code.
   */
  function getOtherTypeCode() { return otherTypeCode_; }

  /**
   * Get the freshness period.
   * @return {float} The freshness period in milliseconds, or null if not
   * specified.
   */
  function getFreshnessPeriod() { return freshnessPeriod_; }

  /**
   * Get the final block ID.
   * @return {NameComponent} The final block ID as a NameComponent. If the
   * NameComponent getValue().size() is 0, then the final block ID is not
   * specified.
   */
  function getFinalBlockId() { return finalBlockId_; }

  /**
   * Set the content type.
   * @param {integer} type The content type as a ContentType enum value. If
   * null, this uses ContentType.BLOB. If the packet's content type is not a
   * recognized ContentType enum value, use ContentType.OTHER_CODE and call
   * setOtherTypeCode().
   */
  function setType(type)
  {
    type_ = (type == null || type < 0) ? ContentType.BLOB : type;
    ++changeCount_;
  }

  /**
   * Set the packet’s content type code to use when the content type enum is
   * ContentType.OTHER_CODE. If the packet’s content type code is a recognized
   * enum value, just call setType().
   * @param {integer} otherTypeCode The packet’s unrecognized content type code,
   * which must be non-negative.
   */
  function setOtherTypeCode(otherTypeCode)
  {
    if (otherTypeCode < 0)
      throw "MetaInfo other type code must be non-negative";

    otherTypeCode_ = otherTypeCode;
    ++changeCount_;
  }

  /**
   * Set the freshness period.
   * @param {float} freshnessPeriod The freshness period in milliseconds, or null
   * for not specified.
   */
  function setFreshnessPeriod(freshnessPeriod)
  {
    if (freshnessPeriod == null || freshnessPeriod < 0)
      freshnessPeriod_ = null;
    else
      freshnessPeriod_ = (typeof freshnessPeriod == "float") ?
        freshnessPeriod : freshnessPeriod.tofloat();
    
    ++changeCount_;
  }

  /**
   * Set the final block ID.
   * @param {NameComponent} finalBlockId The final block ID as a NameComponent.
   * If not specified, set to a new default NameComponent(), or to a
   * NameComponent where getValue().size() is 0.
   */
  function setFinalBlockId(finalBlockId)
  {
    finalBlockId_ = finalBlockId instanceof NameComponent ?
      finalBlockId : NameComponent(finalBlockId);
    ++changeCount_;
  }

  /**
   * Get the change count, which is incremented each time this object is changed.
   * @return {integer} The change count.
   */
  function getChangeCount() { return changeCount_; }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * A GenericSignature extends Signature and holds the encoding bytes of the
 * SignatureInfo so that the application can process experimental signature
 * types. When decoding a packet, if the type of SignatureInfo is not
 * recognized, the library creates a GenericSignature.
 */
class GenericSignature {
  signature_ = null;
  signatureInfoEncoding_ = null;
  typeCode_ = null;
  changeCount_ = 0;

  /**
   * Create a new GenericSignature object, possibly copying values from another
   * object.
   * @param {GenericSignature} value (optional) If value is a GenericSignature,
   * copy its values.  If value is omitted, the signature is unspecified.
   */
  constructor(value = null)
  {
    if (value instanceof GenericSignature) {
      // The copy constructor.
      signature_ = value.signature_;
      signatureInfoEncoding_ = value.signatureInfoEncoding_;
      typeCode_ = value.typeCode_;
    }
    else {
      signature_ = Blob();
      signatureInfoEncoding_ = Blob();
      typeCode_ = null;
    }
  }

  /**
   * Get the data packet's signature bytes.
   * @return {Blob} The signature bytes. If not specified, the value isNull().
   */
  function getSignature() { return signature_; }

  /**
   * Get the bytes of the entire signature info encoding (including the type
   * code).
   * @return {Blob} The encoding bytes. If not specified, the value isNull().
   */
  function getSignatureInfoEncoding() { return signatureInfoEncoding_; }

  /**
   * Get the type code of the signature type. When wire decode calls
   * setSignatureInfoEncoding, it sets the type code. Note that the type code
   * is ignored during wire encode, which simply uses getSignatureInfoEncoding()
   * where the encoding already has the type code.
   * @return {integer} The type code, or null if not known.
   */
  function getTypeCode () { return typeCode_; }

  /**
   * Set the data packet's signature bytes.
   * @param {Blob} signature
   */
  function setSignature(signature)
  {
    signature_ = signature instanceof Blob ? signature : Blob(signature);
    ++changeCount_;
  }

  /**
   * Set the bytes of the entire signature info encoding (including the type
   * code).
   * @param {Blob} signatureInfoEncoding A Blob with the encoding bytes.
   * @param {integer} (optional) The type code of the signature type, or null if
   * not known. (When a GenericSignature is created by wire decoding, it sets
   * the typeCode.)
   */
  function setSignatureInfoEncoding(signatureInfoEncoding, typeCode = null)
  {
    signatureInfoEncoding_ = signatureInfoEncoding instanceof Blob ?
      signatureInfoEncoding : Blob(signatureInfoEncoding);
    typeCode_ = typeCode;
    ++changeCount_;
  }

  /**
   * Get the change count, which is incremented each time this object (or a
   * child object) is changed.
   * @return {integer} The change count.
   */
  function getChangeCount() { return changeCount_; }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * An HmacWithSha256Signature holds the signature bits and other info
 * representing an HmacWithSha256 signature in a packet.
 */
class HmacWithSha256Signature {
  keyLocator_ = null;
  signature_ = null;
  changeCount_ = 0;

  /**
   * Create a new HmacWithSha256Signature object, possibly copying values from
   * another object.
   * @param {HmacWithSha256Signature} value (optional) If value is a
   * HmacWithSha256Signature, copy its values.  If value is omitted, the
   * keyLocator is the default with unspecified values and the signature is
   * unspecified.
   */
  constructor(value = null)
  {
    if (value instanceof HmacWithSha256Signature) {
      // The copy constructor.
      keyLocator_ = ChangeCounter(KeyLocator(value.getKeyLocator()));
      signature_ = value.signature_;
    }
    else {
      keyLocator_ = ChangeCounter(KeyLocator());
      signature_ = Blob();
    }
  }

  /**
   * Implement the clone operator to update this cloned object with values from
   * the original HmacWithSha256Signature which was cloned.
   * param {HmacWithSha256Signature} value The original HmacWithSha256Signature.
   */
  function _cloned(value)
  {
    keyLocator_ = ChangeCounter(KeyLocator(value.getKeyLocator()));
    // We don't need to copy the signature_ Blob.
  }

  /**
   * Get the key locator.
   * @return {KeyLocator} The key locator.
   */
  function getKeyLocator() { return keyLocator_.get(); }

  /**
   * Get the data packet's signature bytes.
   * @return {Blob} The signature bytes. If not specified, the value isNull().
   */
  function getSignature() { return signature_; }

  /**
   * Set the key locator to a copy of the given keyLocator.
   * @param {KeyLocator} keyLocator The KeyLocator to copy.
   */
  function setKeyLocator(keyLocator)
  {
    keyLocator_.set(keyLocator instanceof KeyLocator ?
      KeyLocator(keyLocator) : KeyLocator());
    ++changeCount_;
  }

  /**
   * Set the data packet's signature bytes.
   * @param {Blob} signature
   */
  function setSignature(signature)
  {
    signature_ = signature instanceof Blob ? signature : Blob(signature);
    ++changeCount_;
  }

  /**
   * Get the change count, which is incremented each time this object (or a
   * child object) is changed.
   * @return {integer} The change count.
   */
  function getChangeCount()
  {
    // Make sure each of the checkChanged is called.
    local changed = keyLocator_.checkChanged();
    if (changed)
      // A child object has changed, so update the change count.
      ++changeCount_;

    return changeCount_;
  }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * A Sha256WithRsaSignature holds the signature bits and other info representing
 * a SHA256-with-RSA signature in an interest or data packet.
 */
class Sha256WithRsaSignature {
  keyLocator_ = null;
  signature_ = null;
  changeCount_ = 0;

  /**
   * Create a new Sha256WithRsaSignature object, possibly copying values from
   * another object.
   * @param {Sha256WithRsaSignature} value (optional) If value is a
   * Sha256WithRsaSignature, copy its values.  If value is omitted, the keyLocator
   * is the default with unspecified values and the signature is unspecified.
   */
  constructor(value = null)
  {
    if (value instanceof Sha256WithRsaSignature) {
      // The copy constructor.
      keyLocator_ = ChangeCounter(KeyLocator(value.getKeyLocator()));
      signature_ = value.signature_;
    }
    else {
      keyLocator_ = ChangeCounter(KeyLocator());
      signature_ = Blob();
    }
  }

  /**
   * Implement the clone operator to update this cloned object with values from
   * the original Sha256WithRsaSignature which was cloned.
   * param {Sha256WithRsaSignature} value The original Sha256WithRsaSignature.
   */
  function _cloned(value)
  {
    keyLocator_ = ChangeCounter(KeyLocator(value.getKeyLocator()));
    // We don't need to copy the signature_ Blob.
  }

  /**
   * Get the key locator.
   * @return {KeyLocator} The key locator.
   */
  function getKeyLocator() { return keyLocator_.get(); }

  /**
   * Get the data packet's signature bytes.
   * @return {Blob} The signature bytes. If not specified, the value isNull().
   */
  function getSignature() { return signature_; }

  /**
   * Set the key locator to a copy of the given keyLocator.
   * @param {KeyLocator} keyLocator The KeyLocator to copy.
   */
  function setKeyLocator(keyLocator)
  {
    keyLocator_.set(keyLocator instanceof KeyLocator ?
      KeyLocator(keyLocator) : KeyLocator());
    ++changeCount_;
  }

  /**
   * Set the data packet's signature bytes.
   * @param {Blob} signature
   */
  function setSignature(signature)
  {
    signature_ = signature instanceof Blob ? signature : Blob(signature);
    ++changeCount_;
  }

  /**
   * Get the change count, which is incremented each time this object (or a
   * child object) is changed.
   * @return {integer} The change count.
   */
  function getChangeCount()
  {
    // Make sure each of the checkChanged is called.
    local changed = keyLocator_.checkChanged();
    if (changed)
      // A child object has changed, so update the change count.
      ++changeCount_;

    return changeCount_;
  }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * The Data class represents an NDN Data packet.
 */
class Data {
  name_ = null;
  metaInfo_ = null;
  signature_ = null;
  content_ = null;
  changeCount_ = 0;

  /**
   * Create a new Data object from the optional value.
   * @param {Name|Data} value (optional) If the value is a Name, make a copy and
   * use it as the Data packet's name. If the value is another Data object, copy
   * its values. If the value is null or omitted, set all fields to defaut
   * values.
   */
  constructor(value = null)
  {
    if (value instanceof Data) {
      // The copy constructor.
      name_ = ChangeCounter(Name(value.getName()));
      metaInfo_ = ChangeCounter(MetaInfo(value.getMetaInfo()));
      signature_ = ChangeCounter(clone(value.getSignature()));
      content_ = value.content_;
    }
    else {
      name_ = ChangeCounter(value instanceof Name ? Name(value) : Name());
      metaInfo_ = ChangeCounter(MetaInfo());
      signature_ = ChangeCounter(Sha256WithRsaSignature());
      content_ = Blob();
    }
  }

  /**
   * Get the data packet's name.
   * @return {Name} The name. If not specified, the name size() is 0.
   */
  function getName() { return name_.get(); }

  /**
   * Get the data packet's meta info.
   * @return {MetaInfo} The meta info.
   */
  function getMetaInfo() { return metaInfo_.get(); }

  /**
   * Get the data packet's signature object.
   * @return {Signature} The signature object.
   */
  function getSignature() { return signature_.get(); }

  /**
   * Get the data packet's content.
   * @return {Blob} The content as a Blob, which isNull() if unspecified.
   */
  function getContent() { return content_; }

  // TODO getIncomingFaceId.
  // TODO getFullName.

  /**
   * Set name to a copy of the given Name.
   * @param {Name} name The Name which is copied.
   * @return {Data} This Data so that you can chain calls to update values.
   */
  function setName(name)
  {
    name_.set(name instanceof Name ? Name(name) : Name());
    ++changeCount_;
    return this;
  }

  /**
   * Set metaInfo to a copy of the given MetaInfo.
   * @param {MetaInfo} metaInfo The MetaInfo which is copied.
   * @return {Data} This Data so that you can chain calls to update values.
   */
  function setMetaInfo(metaInfo)
  {
    metaInfo_.set(metaInfo instanceof MetaInfo ? MetaInfo(metaInfo) : MetaInfo());
    ++changeCount_;
    return this;
  }

  /**
   * Set the signature to a copy of the given signature.
   * @param {Signature} signature The signature object which is cloned.
   * @return {Data} This Data so that you can chain calls to update values.
   */
  function setSignature(signature)
  {
    signature_.set(signature == null ?
      Sha256WithRsaSignature() : clone(signature));
    ++changeCount_;
    return this;
  }

  /**
   * Set the content to the given value.
   * @param {Blob|Buffer|blob|Array<integer>} content The content bytes. If
   * content is not a Blob, then create a new Blob to copy the bytes (otherwise
   * take another pointer to the same Blob).
   * @return {Data} This Data so that you can chain calls to update values.
   */
  function setContent(content)
  {
    content_ = content instanceof Blob ? content : Blob(content, true);
    ++changeCount_;
    return this;
  }

  /**
   * Encode this Data for a particular wire format.
   * @param {WireFormat} wireFormat (optional) A WireFormat object used to
   * encode this object. If null or omitted, use WireFormat.getDefaultWireFormat().
   * @return {SignedBlob} The encoded buffer in a SignedBlob object.
   */
  function wireEncode(wireFormat = null)
  {
    if (wireFormat == null)
        // Don't use a default argument since getDefaultWireFormat can change.
        wireFormat = WireFormat.getDefaultWireFormat();

    local result = wireFormat.encodeData(this);
    // To save memory, don't cache the encoding.
    return SignedBlob
      (result.encoding, result.signedPortionBeginOffset,
       result.signedPortionEndOffset);
  }

  /**
   * Decode the input using a particular wire format and update this Data.
   * @param {Blob|Buffer} input The buffer with the bytes to decode.
   * @param {WireFormat} wireFormat (optional) A WireFormat object used to
   * decode this object. If null or omitted, use WireFormat.getDefaultWireFormat().
   */
  function wireDecode(input, wireFormat = null)
  {
    if (wireFormat == null)
        // Don't use a default argument since getDefaultWireFormat can change.
        wireFormat = WireFormat.getDefaultWireFormat();

    local decodeBuffer;
    if (input instanceof Blob)
      wireFormat.decodeData(this, input.buf(), false);
    else
      wireFormat.decodeData(this, input, true);
    // To save memory, don't cache the encoding.
  }

  // TODO: setLpPacket.

  /**
   * Get the change count, which is incremented each time this object (or a
   * child object) is changed.
   * @return {integer} The change count.
   */
  function getChangeCount()
  {
    // Make sure each of the checkChanged is called.
    local changed = name_.checkChanged();
    changed = metaInfo_.checkChanged() || changed;
    changed = signature_.checkChanged() || changed;
    if (changed)
      // A child object has changed, so update the change count.
      ++changeCount_;

    return changeCount_;
  }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * The DerNodeType enum defines the known DER node types.
 */
enum DerNodeType {
  Eoc = 0,
  Boolean = 1,
  Integer = 2,
  BitString = 3,
  OctetString = 4,
  Null = 5,
  ObjectIdentifier = 6,
  ObjectDescriptor = 7,
  External = 40,
  Real = 9,
  Enumerated = 10,
  EmbeddedPdv = 43,
  Utf8String = 12,
  RelativeOid = 13,
  Sequence = 48,
  Set = 49,
  NumericString = 18,
  PrintableString = 19,
  T61String = 20,
  VideoTexString = 21,
  Ia5String = 22,
  UtcTime = 23,
  GeneralizedTime = 24,
  GraphicString = 25,
  VisibleString = 26,
  GeneralString = 27,
  UniversalString = 28,
  CharacterString = 29,
  BmpString = 30
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * DerNode implements the DER node types used in encoding/decoding DER-formatted
 * data.
 */
class DerNode {
  nodeType_ = 0;
  parent_ = null;
  header_ = null;
  payload_ = null;
  payloadPosition_ = 0;

  /**
   * Create a generic DER node with the given nodeType. This is a private
   * constructor used by one of the public DerNode subclasses defined below.
   * @param {integer} nodeType The DER type from the DerNodeType enum.
   */
  constructor(nodeType)
  {
    nodeType_ = nodeType;
    header_ = Buffer(0);
    payload_ = DynamicBlobArray(0);
  }

  /**
   * Return the number of bytes in the DER encoding.
   * @return {integer} The number of bytes.
   */
  function getSize()
  {
    return header_.len() + payloadPosition_;
  }

  /**
   * Encode the given size and update the header.
   * @param {integer} size
   */
  function encodeHeader(size)
  {
    local buffer = DynamicBlobArray(10);
    local bufferPosition = 0;
    buffer.array_[bufferPosition++] = nodeType_;
    if (size < 0)
      // We don't expect this to happen since this is an internal method and
      // always called with the non-negative size() of some buffer.
      throw "DER object has negative length";
    else if (size <= 127)
      buffer.array_[bufferPosition++] = size & 0xff;
    else {
      local tempBuf = DynamicBlobArray(10);
      // We encode backwards from the back.

      local val = size;
      local n = 0;
      while (val != 0) {
        ++n;
        tempBuf.ensureLengthFromBack(n);
        tempBuf.array_[tempBuf.array_.len() - n] = val & 0xff;
        val = val >> 8;
      }
      local nTempBufBytes = n + 1;
      tempBuf.ensureLengthFromBack(nTempBufBytes);
      tempBuf.array_[tempBuf.array_.len() - nTempBufBytes] = ((1<<7) | n) & 0xff;

      buffer.copy(Buffer.from
        (tempBuf.array_, tempBuf.array_.len() - nTempBufBytes), bufferPosition);
      bufferPosition += nTempBufBytes;
    }

    header_ = Buffer.from(buffer.array_, 0, bufferPosition);
  }

  /**
   * Extract the header from an input buffer and return the size.
   * @param {Buffer} inputBuf The input buffer to read from.
   * @param {integer} startIdx The offset into the buffer.
   * @return {integer} The parsed size in the header.
   */
  function decodeHeader(inputBuf, startIdx)
  {
    local idx = startIdx;

    // Use Buffer.get to avoid using the metamethod.
    local nodeType = inputBuf.get(idx) & 0xff;
    idx += 1;

    nodeType_ = nodeType;

    local sizeLen = inputBuf.get(idx) & 0xff;
    idx += 1;

    local header = DynamicBlobArray(10);
    local headerPosition = 0;
    header.array_[headerPosition++] = nodeType;
    header.array_[headerPosition++] = sizeLen;

    local size = sizeLen;
    local isLongFormat = (sizeLen & (1 << 7)) != 0;
    if (isLongFormat) {
      local lenCount = sizeLen & ((1<<7) - 1);
      size = 0;
      while (lenCount > 0) {
        local b = inputBuf.get(idx);
        idx += 1;
        header.ensureLength(headerPosition + 1);
        header.array_[headerPosition++] = b;
        size = 256 * size + (b & 0xff);
        lenCount -= 1;
      }
    }

    header_ = Buffer.from(header.array_, 0, headerPosition);
    return size;
  }

  // TODO: encode

  /**
   * Decode and store the data from an input buffer.
   * @param {Buffer} inputBuf The input buffer to read from. This reads from
   * startIdx (regardless of the buffer's position) and does not change the
   * position.
   * @param {integer} startIdx The offset into the buffer.
   */
  function decode(inputBuf, startIdx)
  {
    local idx = startIdx;
    local payloadSize = decodeHeader(inputBuf, idx);
    local skipBytes = header_.len();
    if (payloadSize > 0) {
      idx += skipBytes;
      payloadAppend(inputBuf.slice(idx, idx + payloadSize));
    }
  }

  /**
   * Copy buffer to payload_ at payloadPosition_ and update payloadPosition_.
   * @param {Buffer} buffer The buffer to copy.
   */
  function payloadAppend(buffer)
  {
    payloadPosition_ = payload_.copy(buffer, payloadPosition_);
  }

  /**
   * Parse the data from the input buffer recursively and return the root as an
   * object of a subclass of DerNode.
   * @param {Buffer} inputBuf The input buffer to read from.
   * @param {integer} startIdx (optional) The offset into the buffer. If
   * omitted, use 0.
   * @return {DerNode} An object of a subclass of DerNode.
   */
  static function parse(inputBuf, startIdx = 0)
  {
    // Use Buffer.get to avoid using the metamethod.
    local nodeType = inputBuf.get(startIdx) & 0xff;
    // Don't increment idx. We're just peeking.

    local newNode;
    if (nodeType == DerNodeType.Boolean)
      newNode = DerNode_DerBoolean();
    else if (nodeType == DerNodeType.Integer)
      newNode = DerNode_DerInteger();
    else if (nodeType == DerNodeType.BitString)
      newNode = DerNode_DerBitString();
    else if (nodeType == DerNodeType.OctetString)
      newNode = DerNode_DerOctetString();
    else if (nodeType == DerNodeType.Null)
      newNode = DerNode_DerNull();
    else if (nodeType == DerNodeType.ObjectIdentifier)
      newNode = DerNode_DerOid();
    else if (nodeType == DerNodeType.Sequence)
      newNode = DerNode_DerSequence();
    else if (nodeType == DerNodeType.PrintableString)
      newNode = DerNode_DerPrintableString();
    else if (nodeType == DerNodeType.GeneralizedTime)
      newNode = DerNode_DerGeneralizedTime();
    else
      throw "Unimplemented DER type " + nodeType;

    newNode.decode(inputBuf, startIdx);
    return newNode;
  }

  /**
   * Convert the encoded data to a standard representation. Overridden by some
   * subclasses (e.g. DerBoolean).
   * @return {Blob} The encoded data as a Blob.
   */
  function toVal() { return encode(); }

  /**
   * Get a copy of the payload bytes.
   * @return {Blob} A copy of the payload.
   */
  function getPayload()
  {
    payload_.array_.seek(0);
    return Blob(payload_.array_.readblob(payloadPosition_), false);
  }

  /**
   * If this object is a DerNode_DerSequence, get the children of this node.
   * Otherwise, throw an exception. (DerSequence overrides to implement this
   * method.)
   * @return {Array<DerNode>} The children as an array of DerNode.
   * @throws string if this object is not a Dernode_DerSequence.
   */
  function getChildren() { throw "not implemented"; }

  /**
   * Check that index is in bounds for the children list, return children[index].
   * @param {Array<DerNode>} children The list of DerNode, usually returned by
   * another call to getChildren.
   * @param {integer} index The index of the children.
   * @return {DerNode_DerSequence} children[index].
   * @throws string if index is out of bounds or if children[index] is not a
   * DerNode_DerSequence.
   */
  static function getSequence(children, index)
  {
    if (index < 0 || index >= children.len())
      throw "Child index is out of bounds";

    if (!(children[index] instanceof DerNode_DerSequence))
      throw "Child DerNode is not a DerSequence";

    return children[index];
  }
}

/**
 * A DerNode_DerStructure extends DerNode to hold other DerNodes.
 */
class DerNode_DerStructure extends DerNode {
  childChanged_ = false;
  nodeList_ = null;
  size_ = 0;

  /**
   * Create a DerNode_DerStructure with the given nodeType. This is a private
   * constructor. To create an object, use DerNode_DerSequence.
   * @param {integer} nodeType One of the defined DER DerNodeType constants.
   */
  constructor(nodeType)
  {
    // Call the base constructor.
    base.constructor(nodeType);

    nodeList_ = []; // Of DerNode.
  }

  /**
   * Get the total length of the encoding, including children.
   * @return {integer} The total (header + payload) length.
   */
  function getSize()
  {
    if (childChanged_) {
      updateSize();
      childChanged_ = false;
    }

    encodeHeader(size_);
    return size_ + header_.len();
  };

  /**
   * Get the children of this node.
   * @return {Array<DerNode>} The children as an array of DerNode.
   */
  function getChildren() { return nodeList_; }

  function updateSize()
  {
    local newSize = 0;

    for (local i = 0; i < nodeList_.len(); ++i) {
      local n = nodeList_[i];
      newSize += n.getSize();
    }

    size_ = newSize;
    childChanged_ = false;
  };

  /**
   * Add a child to this node.
   * @param {DerNode} node The child node to add.
   * @param {bool} (optional) notifyParent Set to true to cause any containing
   * nodes to update their size.  If omitted, use false.
   */
  function addChild(node, notifyParent = false)
  {
    node.parent_ = this;
    nodeList_.append(node);

    if (notifyParent) {
      if (parent_ != null)
        parent_.setChildChanged();
    }

    childChanged_ = true;
  }

  /**
   * Mark the child list as dirty, so that we update size when necessary.
   */
  function setChildChanged()
  {
    if (parent_ != null)
      parent_.setChildChanged();
    childChanged_ = true;
  }

  // TODO: encode

  /**
   * Override the base decode to decode and store the data from an input
   * buffer. Recursively populates child nodes.
   * @param {Buffer} inputBuf The input buffer to read from.
   * @param {integer} startIdx The offset into the buffer.
   */
  function decode(inputBuf, startIdx)
  {
    local idx = startIdx;
    size_ = decodeHeader(inputBuf, idx);
    idx += header_.len();

    local accSize = 0;
    while (accSize < size_) {
      local node = DerNode.parse(inputBuf, idx);
      local size = node.getSize();
      idx += size;
      accSize += size;
      addChild(node, false);
    }
  }
}

////////
// Now for all the node types...
////////

/**
 * A DerNode_DerByteString extends DerNode to handle byte strings.
 */
class DerNode_DerByteString extends DerNode {
  /**
   * Create a DerNode_DerByteString with the given inputData and nodeType. This
   * is a private constructor used by one of the public subclasses such as
   * DerOctetString or DerPrintableString.
   * @param {Buffer} inputData An input buffer containing the string to encode.
   * @param {integer} nodeType One of the defined DER DerNodeType constants.
   */
  constructor(inputData = null, nodeType = null)
  {
    // Call the base constructor.
    base.constructor(nodeType);

    if (inputData != null) {
      payloadAppend(inputData);
      encodeHeader(inputData.len());
    }
  }

  /**
   * Override to return just the byte string.
   * @return {Blob} The byte string as a copy of the payload buffer.
   */
  function toVal() { return getPayload(); }
}

// TODO: DerNode_DerBoolean

/**
 * DerNode_DerInteger extends DerNode to encode an integer value.
 */
class DerNode_DerInteger extends DerNode {
  /**
   * Create a DerNode_DerInteger for the value.
   * @param {integer|Buffer} integer The value to encode. If integer is a Buffer
   * byte array of a positive integer, you must ensure that the first byte is
   * less than 0x80.
   */
  constructor(integer = null)
  {
    // Call the base constructor.
    base.constructor(DerNodeType.Integer);

    if (integer != null) {
      if (Buffer.isBuffer(integer)) {
        if (integer.len() > 0 && integer.get(0) >= 0x80)
          throw "Negative integers are not currently supported";

        if (integer.len() == 0)
          payloadAppend(Buffer([0]));
        else
          payloadAppend(integer);
      }
      else {
        if (integer < 0)
          throw "Negative integers are not currently supported";

        // Convert the integer to bytes the easy/slow way.
        local temp = DynamicBlobArray(10);
        // We encode backwards from the back.
        local length = 0;
        while (true) {
          ++length;
          temp.ensureLengthFromBack(length);
          temp.array_[temp.array_.len() - length] = integer & 0xff;
          integer = integer >> 8;

          if (integer <= 0)
            // We check for 0 at the end so we encode one byte if it is 0.
            break;
        }

        if (temp.array_[temp.array_.len() - length] >= 0x80) {
          // Make it a non-negative integer.
          ++length;
          temp.ensureLengthFromBack(length);
          temp.array_[temp.array_.len() - length] = 0;
        }

        payloadAppend(Buffer.from(temp.array_, temp.array_.len() - length));
      }

      encodeHeader(payloadPosition_);
    }
  }

  function toVal()
  {
    if (payloadPosition_ > 0 && payload_.array[0] >= 0x80)
      throw "Negative integers are not currently supported";

    local result = 0;
    for (local i = 0; i < payloadPosition_; ++i) {
      result = result << 8;
      result += payload_.array_[i];
    }

    return result;
  }

  /**
   * Return an array of bytes, removing the leading zero, if any.
   * @return {Array<integer>} The array of bytes.
   */
  function toUnsignedArray()
  {
    local iFrom = (payloadPosition_ > 1 && payload_.array_[0] == 0) ? 1 : 0;
    local result = array(payloadPosition_ - iFrom);
    local iTo = 0;
    while (iFrom < payloadPosition_)
      result[iTo++] = payload_.array_[iFrom++];

    return result;
  }
}

/**
 * A DerNode_DerBitString extends DerNode to handle a bit string.
 */
class DerNode_DerBitString extends DerNode {
  /**
   * Create a DerBitString with the given padding and inputBuf.
   * @param {Buffer} inputBuf An input buffer containing the bit octets to encode.
   * @param {integer} paddingLen The number of bits of padding at the end of the
   * bit string. Should be less than 8.
   */
  constructor(inputBuf = null, paddingLen = null)
  {
    // Call the base constructor.
    base.constructor(DerNodeType.BitString);

    if (inputBuf != null) {
      payload_.ensureLength(payloadPosition_ + 1);
      payload_.array_[payloadPosition_++] = paddingLen & 0xff;
      payloadAppend(inputBuf);
      encodeHeader(payloadPosition_);
    }
  }
}

/**
 * DerNode_DerOctetString extends DerNode_DerByteString to encode a string of
 * bytes.
 */
class DerNode_DerOctetString extends DerNode_DerByteString {
  /**
   * Create a DerOctetString for the inputData.
   * @param {Buffer} inputData An input buffer containing the string to encode.
   */
  constructor(inputData = null)
  {
    // Call the base constructor.
    base.constructor(inputData, DerNodeType.OctetString);
  }
}

/**
 * A DerNode_DerNull extends DerNode to encode a null value.
 */
class DerNode_DerNull extends DerNode {
  /**
   * Create a DerNull.
   */
  constructor()
  {
    // Call the base constructor.
    base.constructor(DerNodeType.Null);

    encodeHeader(0);
  }
}

/**
 * A DerNode_DerOid extends DerNode to represent an object identifier.
 */
class DerNode_DerOid extends DerNode {
  /**
   * Create a DerOid with the given object identifier. The object identifier
   * string must begin with 0,1, or 2 and must contain at least 2 digits.
   * @param {string|OID} oid The OID string or OID object to encode.
   */
  constructor(oid = null)
  {
    // Call the base constructor.
    base.constructor(DerNodeType.ObjectIdentifier);

    if (oid != null) {
      // TODO: Implement oid decoding.
      throw "not implemented";
    }
  }

  // TODO: prepareEncoding
  // TODO: encode128
  // TODO: decode128
  // TODO: toVal
}

/**
 * A DerNode_DerSequence extends DerNode_DerStructure to contains an ordered
 * sequence of other nodes.
 */
class DerNode_DerSequence extends DerNode_DerStructure {
  /**
   * Create a DerSequence.
   */
  constructor()
  {
    // Call the base constructor.
    base.constructor(DerNodeType.Sequence);
  }
}

// TODO: DerNode_DerPrintableString
// TODO: DerNode_DerGeneralizedTime
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

enum Tlv {
  Interest =         5,
  Data =             6,
  Name =             7,
  ImplicitSha256DigestComponent = 1,
  NameComponent =    8,
  Selectors =        9,
  Nonce =            10,
  // <Unassigned> =      11,
  InterestLifetime = 12,
  MinSuffixComponents = 13,
  MaxSuffixComponents = 14,
  PublisherPublicKeyLocator = 15,
  Exclude =          16,
  ChildSelector =    17,
  MustBeFresh =      18,
  Any =              19,
  MetaInfo =         20,
  Content =          21,
  SignatureInfo =    22,
  SignatureValue =   23,
  ContentType =      24,
  FreshnessPeriod =  25,
  FinalBlockId =     26,
  SignatureType =    27,
  KeyLocator =       28,
  KeyLocatorDigest = 29,
  SelectedDelegation = 32,
  FaceInstance =     128,
  ForwardingEntry =  129,
  StatusResponse =   130,
  Action =           131,
  FaceID =           132,
  IPProto =          133,
  Host =             134,
  Port =             135,
  MulticastInterface = 136,
  MulticastTTL =     137,
  ForwardingFlags =  138,
  StatusCode =       139,
  StatusText =       140,

  SignatureType_DigestSha256 = 0,
  SignatureType_SignatureSha256WithRsa = 1,
  SignatureType_SignatureSha256WithEcdsa = 3,
  SignatureType_SignatureHmacWithSha256 = 4,

  ContentType_Default = 0,
  ContentType_Link =    1,
  ContentType_Key =     2,

  NfdCommand_ControlResponse = 101,
  NfdCommand_StatusCode =      102,
  NfdCommand_StatusText =      103,

  ControlParameters_ControlParameters =   104,
  ControlParameters_FaceId =              105,
  ControlParameters_Uri =                 114,
  ControlParameters_LocalControlFeature = 110,
  ControlParameters_Origin =              111,
  ControlParameters_Cost =                106,
  ControlParameters_Flags =               108,
  ControlParameters_Strategy =            107,
  ControlParameters_ExpirationPeriod =    109,

  LpPacket_LpPacket =        100,
  LpPacket_Fragment =         80,
  LpPacket_Sequence =         81,
  LpPacket_FragIndex =        82,
  LpPacket_FragCount =        83,
  LpPacket_Nack =            800,
  LpPacket_NackReason =      801,
  LpPacket_NextHopFaceId =   816,
  LpPacket_IncomingFaceId =  817,
  LpPacket_CachePolicy =     820,
  LpPacket_CachePolicyType = 821,
  LpPacket_IGNORE_MIN =      800,
  LpPacket_IGNORE_MAX =      959,

  Link_Preference = 30,
  Link_Delegation = 31,

  Encrypt_EncryptedContent = 130,
  Encrypt_EncryptionAlgorithm = 131,
  Encrypt_EncryptedPayload = 132,
  Encrypt_InitialVector = 133,

  // For RepetitiveInterval.
  Encrypt_StartDate = 134,
  Encrypt_EndDate = 135,
  Encrypt_IntervalStartHour = 136,
  Encrypt_IntervalEndHour = 137,
  Encrypt_NRepeats = 138,
  Encrypt_RepeatUnit = 139,
  Encrypt_RepetitiveInterval = 140,

  // For Schedule.
  Encrypt_WhiteIntervalList = 141,
  Encrypt_BlackIntervalList = 142,
  Encrypt_Schedule = 143
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * A TlvDecoder has methods to decode an input according to NDN-TLV.
 */
class TlvDecoder {
  input_ = null;
  offset_ = 0;

  /**
   * Create a new TlvDecoder for decoding the input in the NDN-TLV wire format.
   * @param {Buffer} input The Buffer with the bytes to decode.
   */
  constructor(input)
  {
    input_ = input;
  }

  /**
   * Decode VAR-NUMBER in NDN-TLV and return it. Update the offset.
   * @return {integer} The decoded VAR-NUMBER.
   */
  function readVarNumber()
  {
    // Use Buffer.get to avoid using the metamethod.
    local firstOctet = input_.get(offset_);
    offset_ += 1;
    if (firstOctet < 253)
      return firstOctet;
    else
      return readExtendedVarNumber_(firstOctet);
  }

  /**
   * A private method to do the work of readVarNumber, given the firstOctet
   * which is >= 253.
   * @param {integer} firstOctet The first octet which is >= 253, used to decode
   * the remaining bytes.
   * @return {integer} The decoded VAR-NUMBER.
   * @throws string if the VAR-NUMBER is 64-bit or read past the end of the
   * input.
   */
  function readExtendedVarNumber_(firstOctet)
  {
    local result;
    // This is a private function so we know firstOctet >= 253.
    if (firstOctet == 253) {
      // Use Buffer.get to avoid using the metamethod.
      result = ((input_.get(offset_) << 8) +
                 input_.get(offset_ + 1));
      offset_ += 2;
    }
    else if (firstOctet == 254) {
      // Use abs because << 24 can set the high bit of the 32-bit int making it negative.
      result = (math.abs(input_.get(offset_) << 24) +
                        (input_.get(offset_ + 1) << 16) +
                        (input_.get(offset_ + 2) << 8) +
                         input_.get(offset_ + 3));
      offset_ += 4;
    }
    else
      throw "Decoding a 64-bit VAR-NUMBER is not supported";

    return result;
  }

  /**
   * Decode the type and length from this's input starting at offset, expecting
   * the type to be expectedType and return the length. Update offset.  Also make
   * sure the decoded length does not exceed the number of bytes remaining in the
   * input.
   * @param {integer} expectedType The expected type.
   * @return {integer} The length of the TLV.
   * @throws string if (did not get the expected TLV type or the TLV length
   * exceeds the buffer length.
   */
  function readTypeAndLength(expectedType)
  {
    local type = readVarNumber();
    if (type != expectedType)
      throw "Did not get the expected TLV type";

    local length = readVarNumber();
    if (offset_ + length > input_.len())
      throw "TLV length exceeds the buffer length";

    return length;
  }

  /**
   * Decode the type and length from the input starting at offset, expecting the
   * type to be expectedType.  Update offset.  Also make sure the decoded length
   * does not exceed the number of bytes remaining in the input. Return the offset
   * of the end of this parent TLV, which is used in decoding optional nested
   * TLVs. After reading all nested TLVs, call finishNestedTlvs.
   * @param {integer} expectedType The expected type.
   * @return {integer} The offset of the end of the parent TLV.
   * @throws string if did not get the expected TLV type or the TLV length
   * exceeds the buffer length.
   */
  function readNestedTlvsStart(expectedType)
  {
    return readTypeAndLength(expectedType) + offset_;
  }

  /**
   * Call this after reading all nested TLVs to skip any remaining unrecognized
   * TLVs and to check if the offset after the final nested TLV matches the
   * endOffset returned by readNestedTlvsStart.
   * @param {integer} endOffset The offset of the end of the parent TLV, returned
   * by readNestedTlvsStart.
   * @throws string if the TLV length does not equal the total length of the
   * nested TLVs.
   */
  function finishNestedTlvs(endOffset)
  {
    // We expect offset to be endOffset, so check this first.
    if (offset_ == endOffset)
      return;

    // Skip remaining TLVs.
    while (offset_ < endOffset) {
      // Skip the type VAR-NUMBER.
      readVarNumber();
      // Read the length and update offset.
      local length = readVarNumber();
      offset_ += length;

      if (offset_ > input_.len())
        throw "TLV length exceeds the buffer length";
    }

    if (offset_ != endOffset)
      throw "TLV length does not equal the total length of the nested TLVs";
  }

  /**
   * Decode the type from this's input starting at offset, and if it is the
   * expectedType, then return true, else false.  However, if this's offset is
   * greater than or equal to endOffset, then return false and don't try to read
   * the type. Do not update offset.
   * @param {integer} expectedType The expected type.
   * @param {integer} endOffset The offset of the end of the parent TLV, returned
   * by readNestedTlvsStart.
   * @return {bool} true if the type of the next TLV is the expectedType,
   * otherwise false.
   */
  function peekType(expectedType, endOffset)
  {
    if (offset_ >= endOffset)
      // No more sub TLVs to look at.
      return false;
    else {
      local saveOffset = offset_;
      local type = readVarNumber();
      // Restore offset.
      offset_ = saveOffset;

      return type == expectedType;
    }
  }

  /**
   * Decode a non-negative integer in NDN-TLV and return it. Update offset by
   * length.
   * @param {integer} length The number of bytes in the encoded integer.
   * @return {integer} The integer.
   * @throws string if the VAR-NUMBER is 64-bit or if length is an invalid
   * length for a TLV non-negative integer.
   */
  function readNonNegativeInteger(length)
  {
    local result;
    if (length == 1)
      // Use Buffer.get to avoid using the metamethod.
      result = input_.get(offset_);
    else if (length == 2)
      result = ((input_.get(offset_) << 8) +
                 input_.get(offset_ + 1));
    else if (length == 4)
      // Use abs because << 24 can set the high bit of the 32-bit int making it negative.
      result = (math.abs(input_.get(offset_) << 24) +
                        (input_.get(offset_ + 1) << 16) +
                        (input_.get(offset_ + 2) << 8) +
                         input_.get(offset_ + 3));
    else if (length == 8)
      throw "Decoding a 64-bit VAR-NUMBER is not supported";
    else
      throw "Invalid length for a TLV nonNegativeInteger";

    offset_ += length;
    return result;
  }

  /**
   * Decode the type and length from this's input starting at offset, expecting
   * the type to be expectedType. Then decode a non-negative integer in NDN-TLV
   * and return it.  Update offset.
   * @param {integer} expectedType The expected type.
   * @return {integer} The integer.
   * @throws string if did not get the expected TLV type or can't decode the
   * value.
   */
  function readNonNegativeIntegerTlv(expectedType)
  {
    local length = readTypeAndLength(expectedType);
    return readNonNegativeInteger(length);
  }
  
  /**
   * Peek at the next TLV, and if it has the expectedType then call
   * readNonNegativeIntegerTlv and return the integer.  Otherwise, return null.
   * However, if this's offset is greater than or equal to endOffset, then return
   * null and don't try to read the type.
   * @param {integer} expectedType The expected type.
   * @param {integer} endOffset The offset of the end of the parent TLV, returned
   * by readNestedTlvsStart.
   * @return {integer} The integer or null if the next TLV doesn't have the
   * expected type.
   */
  function readOptionalNonNegativeIntegerTlv(expectedType, endOffset)
  {
    if (peekType(expectedType, endOffset))
      return readNonNegativeIntegerTlv(expectedType);
    else
      return null;
  }

  /**
   * Decode the type and length from this's input starting at offset, expecting
   * the type to be expectedType. Then return an array of the bytes in the value.
   * Update offset.
   * @param {integer} expectedType The expected type.
   * @return {Buffer} The bytes in the value as a Buffer. This is a slice onto a
   * portion of the input Buffer.
   * @throws string if did not get the expected TLV type.
   */
  function readBlobTlv(expectedType)
  {
    local length = readTypeAndLength(expectedType);
    local result = getSlice(offset_, offset_ + length);

    // readTypeAndLength already checked if length exceeds the input buffer.
    offset_ += length;
    return result;
  }

  /**
   * Peek at the next TLV, and if it has the expectedType then call readBlobTlv
   * and return the value.  Otherwise, return null. However, if this's offset is
   * greater than or equal to endOffset, then return null and don't try to read
   * the type.
   * @param {integer} expectedType The expected type.
   * @param {integer} endOffset The offset of the end of the parent TLV, returned
   * by readNestedTlvsStart.
   * @return {Buffer} The bytes in the value as Buffer or null if the next TLV
   * doesn't have the expected type. This is a slice onto a portion of the input
   * Buffer.
   */
  function readOptionalBlobTlv(expectedType, endOffset)
  {
    if (peekType(expectedType, endOffset))
      return readBlobTlv(expectedType);
    else
      return null;
  }

  /**
   * Peek at the next TLV, and if it has the expectedType then read a type and
   * value, ignoring the value, and return true. Otherwise, return false.
   * However, if this's offset is greater than or equal to endOffset, then return
   * false and don't try to read the type.
   * @param {integer} expectedType The expected type.
   * @param {integer} endOffset The offset of the end of the parent TLV, returned
   * by readNestedTlvsStart.
   * @return {bool} true, or else false if the next TLV doesn't have the
   * expected type.
   */
  function readBooleanTlv(expectedType, endOffset)
  {
    if (peekType(expectedType, endOffset)) {
      local length = readTypeAndLength(expectedType);
      // We expect the length to be 0, but update offset anyway.
      offset_ += length;
      return true;
    }
    else
      return false;
  }

  /**
   * Get the offset into the input, used for the next read.
   * @return {integer} The offset.
   */
  function getOffset() { return offset_; }

  /**
   * Set the offset into the input, used for the next read.
   * @param {integer} offset The new offset.
   */
  function seek(offset) { offset_ = offset; }

  /**
   * Return a slice of the input for the given offset range.
   * @param {integer} beginOffset The offset in the input of the beginning of
   * the slice.
   * @param {integer} endOffset The offset in the input of the end of the slice
   * (not inclusive).
   * @return {Buffer} The bytes in the value as a Buffer. This is a slice onto a
   * portion of the input Buffer.
   */
  function getSlice(beginOffset, endOffset)
  {
    return input_.slice(beginOffset, endOffset);
  }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * A TlvEncoder holds an output buffer and has methods to output NDN-TLV.
 */
class TlvEncoder {
  output_ = null;
  // length is the number of bytes that have been written to the back of
  // output_.array_.
  length_ = 0;

  /**
   * Create a new TlvEncoder to use a DynamicBlobArray with the initialSize.
   * When done, you should call getOutput().
   * @param initialSize {integer} (optional) The initial size of output buffer.
   * If omitted, use a default value.
   */
  constructor(initialSize = 16)
  {
    output_ = DynamicBlobArray(initialSize);
  }

  /**
   * Get the number of bytes that have been written to the output.  You can
   * save this number, write sub TLVs, then subtract the new length from this
   * to get the total length of the sub TLVs.
   * @return {integer} The number of bytes that have been written to the output.
   */
  function getLength() { return length_; }

  /**
   * Encode varNumber as a VAR-NUMBER in NDN-TLV and write it to the output just
    * before array_.len() from the back. Advance length_.
   * @param {integer} varNumber The number to encode.
   */
  function writeVarNumber(varNumber)
  {
    if (varNumber < 0)
      throw "TlvEncoder: Can't have a negative VAR-NUMBER";

    if (varNumber < 253) {
      length_ += 1;
      output_.ensureLengthFromBack(length_);
      output_.array_[output_.array_.len() - length_] = varNumber & 0xff;
    }
    else if (varNumber <= 0xffff) {
      length_ += 3;
      output_.ensureLengthFromBack(length_);
      local array = output_.array_;
      local offset = array.len() - length_;
      array[offset] = 253;
      array[offset + 1] = (varNumber >> 8) & 0xff;
      array[offset + 2] = varNumber & 0xff;
    }
    else {
      length_ += 5;
      output_.ensureLengthFromBack(length_);
      local array = array;
      local offset = array.len() - length_;
      array[offset] = 254;
      array[offset + 1] = (varNumber >> 24) & 0xff;
      array[offset + 2] = (varNumber >> 16) & 0xff;
      array[offset + 3] = (varNumber >> 8) & 0xff;
      array[offset + 4] = varNumber & 0xff;
    }
    // TODO: Can Squirrel have a 64-bit integer?
  }

  /**
   * Write the type and length to the output just before array_.len() from the
   * back. Advance length_.
   * @param {integer} type the type of the TLV.
   * @param {integer} length The length of the TLV.
   */
  function writeTypeAndLength(type, length)
  {
    // Write backwards.
    writeVarNumber(length);
    writeVarNumber(type);
  }

  /**
   * Encode value as a non-negative integer in NDN-TLV and write it to the 
   * output just before array_.len() from the back. This does not write a type
   * or length for the value. Advance length_.
   * @param {integer} value The integer to encode.
   */
  function writeNonNegativeInteger(value)
  {
    if (value < 0)
      throw "TlvEncoder: Non-negative integer cannot be negative";

    if (value <= 0xff) {
      length_ += 1;
      output_.ensureLengthFromBack(length_);
      output_.array_[output_.array_.len() - length_] = value & 0xff;
    }
    else if (value <= 0xffff) {
      length_ += 2;
      output_.ensureLengthFromBack(length_);
      local array = output_.array_;
      local offset = array.len() - length_;
      array[offset]     = (value >> 8) & 0xff;
      array[offset + 1] = value & 0xff;
    }
    else {
      length_ += 4;
      output_.ensureLengthFromBack(length_);
      local array = output_.array_;
      local offset = array.len() - length_;
      array[offset]     = (value >> 24) & 0xff;
      array[offset + 1] = (value >> 16) & 0xff;
      array[offset + 2] = (value >> 8) & 0xff;
      array[offset + 3] = value & 0xff;
    }
    // TODO: Can Squirrel have a 64-bit integer?
  }

  /**
   * Write the type, then the length of the encoded value then encode value as a
   * non-negative integer and write it to the output just before array_.len() 
   * from the back. Advance length_. (If you want to just write the non-negative
   * integer, use writeNonNegativeInteger.)
   * @param {integer} type the type of the TLV.
   * @param {integer} value The integer to encode.
   */
  function writeNonNegativeIntegerTlv(type, value)
  {
    // Write backwards.
    local saveLength = length_;
    writeNonNegativeInteger(value);
    writeTypeAndLength(type, length_ - saveLength);
  }

  /**
   * If value is negative or null then do nothing, otherwise call
   * writeNonNegativeIntegerTlv.
   * @param {integer} type the type of the TLV.
   * @param {integer} value Negative or null for none, otherwise the integer to
   * encode.
   */
  function writeOptionalNonNegativeIntegerTlv(type, value)
  {
    if (value != null && value >= 0)
      return writeNonNegativeIntegerTlv(type, value);
  }

  /**
   * If value is negative or null then do nothing, otherwise call
   * writeNonNegativeIntegerTlv.
   * @param {integer} type the type of the TLV.
   * @param {float} value Negative or null for none, otherwise use round(value).
   */
  function writeOptionalNonNegativeIntegerTlvFromFloat(type, value)
  {
    if (value != null && value >= 0.0)
      // math doesn't have round, so use floor.
      return writeNonNegativeIntegerTlv(type, math.floor(value + 0.5).tointeger());
  }

  /**
   * Copy the bytes of the buffer to the output just before array_.len() from 
   * the back. Advance length_. Note that this does not encode a type and
   * length; for that see writeBlobTlv.
   * @param {Buffer} buffer A Buffer with the bytes to copy.
   */
  function writeBuffer(buffer)
  {
    if (buffer == null)
      return;

    length_ += buffer.len();
    output_.copyFromBack(buffer, length_);
  }

  /**
   * Write the type, then the length of the blob then the blob value to the 
   * output just before array_.len() from the back. Advance length_.
   * @param {integer} type the type of the TLV.
   * @param {Buffer} value A Buffer with the bytes to copy.
   */
  function writeBlobTlv(type, value)
  {
    if (value == null) {
      writeTypeAndLength(type, 0);
      return;
    }

    // Write backwards.
    writeBuffer(value);
    writeTypeAndLength(type, value.len());
  }

  /**
   * If value is null or 0 length then do nothing, otherwise call writeBlobTlv.
   * @param {integer} type the type of the TLV.
   * @param {Buffer} value A Buffer with the bytes to copy.
   */
  function writeOptionalBlobTlv(type, value)
  {
    if (value != null && value.len() > 0)
      writeBlobTlv(type, value);
  }

  /**
   * Transfer the encoding bytes to a Blob and return the Blob. Set this
   * object's output array to null to prevent further use.
   * @return {Blob} A new NDN Blob with the output.
   */
  function finish()
  {
    return output_.finishFromBack(length_);
  }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

const TlvStructureDecoder_READ_TYPE =         0;
const TlvStructureDecoder_READ_TYPE_BYTES =   1;
const TlvStructureDecoder_READ_LENGTH =       2;
const TlvStructureDecoder_READ_LENGTH_BYTES = 3;
const TlvStructureDecoder_READ_VALUE_BYTES =  4;

/**
 * A TlvStructureDecoder finds the end of an NDN-TLV element, even if the
 * element is supplied in parts.
 */
class TlvStructureDecoder {
  gotElementEnd_ = false;
  offset_ = 0;
  state_ = TlvStructureDecoder_READ_TYPE;
  headerLength_ = 0;
  useHeaderBuffer_ = false;
  // 8 bytes is enough to hold the extended bytes in the length encoding
  // where it is an 8-byte number.
  headerBuffer_ = null;
  nBytesToRead_ = 0;
  firstOctet_ = 0;

  constructor() {
    headerBuffer_ = Buffer(8);
  }

  /**
   * Continue scanning input starting from offset_ to find the element end. If the
   * end of the element which started at offset 0 is found, this returns true and
   * getOffset() is the length of the element. Otherwise, this returns false which
   * means you should read more into input and call again.
   * @param {Buffer} input The input buffer. You have to pass in input each time
   * because the buffer could be reallocated.
   * @return {bool} True if found the element end, false if not.
   */
  function findElementEnd(input)
  {
    if (gotElementEnd_)
      // Someone is calling when we already got the end.
      return true;

    local decoder = TlvDecoder(input);

    while (true) {
      if (offset_ >= input.len())
        // All the cases assume we have some input. Return and wait for more.
        return false;

      if (state_ == TlvStructureDecoder_READ_TYPE) {
        // Use Buffer.get to avoid using the metamethod.
        local firstOctet = input.get(offset_);
        offset_ += 1;
        if (firstOctet < 253)
          // The value is simple, so we can skip straight to reading the length.
          state_ = TlvStructureDecoder_READ_LENGTH;
        else {
          // Set up to skip the type bytes.
          if (firstOctet == 253)
            nBytesToRead_ = 2;
          else if (firstOctet == 254)
            nBytesToRead_ = 4;
          else
            // value == 255.
            nBytesToRead_ = 8;

          state_ = TlvStructureDecoder_READ_TYPE_BYTES;
        }
      }
      else if (state_ == TlvStructureDecoder_READ_TYPE_BYTES) {
        local nRemainingBytes = input.len() - offset_;
        if (nRemainingBytes < nBytesToRead_) {
          // Need more.
          offset_ += nRemainingBytes;
          nBytesToRead_ -= nRemainingBytes;
          return false;
        }

        // Got the type bytes. Move on to read the length.
        offset_ += nBytesToRead_;
        state_ = TlvStructureDecoder_READ_LENGTH;
      }
      else if (state_ == TlvStructureDecoder_READ_LENGTH) {
        // Use Buffer.get to avoid using the metamethod.
        local firstOctet = input.get(offset_);
        offset_ += 1;
        if (firstOctet < 253) {
          // The value is simple, so we can skip straight to reading
          //  the value bytes.
          nBytesToRead_ = firstOctet;
          if (nBytesToRead_ == 0) {
            // No value bytes to read. We're finished.
            gotElementEnd_ = true;
            return true;
          }

          state_ = TlvStructureDecoder_READ_VALUE_BYTES;
        }
        else {
          // We need to read the bytes in the extended encoding of
          //  the length.
          if (firstOctet == 253)
            nBytesToRead_ = 2;
          else if (firstOctet == 254)
            nBytesToRead_ = 4;
          else
            // value == 255.
            nBytesToRead_ = 8;

          // We need to use firstOctet in the next state.
          firstOctet_ = firstOctet;
          state_ = TlvStructureDecoder_READ_LENGTH_BYTES;
        }
      }
      else if (state_ == TlvStructureDecoder_READ_LENGTH_BYTES) {
        local nRemainingBytes = input.len() - offset_;
        if (!useHeaderBuffer_ && nRemainingBytes >= nBytesToRead_) {
          // We don't have to use the headerBuffer. Set nBytesToRead.
          decoder.seek(offset_);

          nBytesToRead_ = decoder.readExtendedVarNumber_(firstOctet_);
          // Update offset_ to the decoder's offset after reading.
          offset_ = decoder.getOffset();
        }
        else {
          useHeaderBuffer_ = true;

          local nNeededBytes = nBytesToRead_ - headerLength_;
          if (nNeededBytes > nRemainingBytes) {
            // We can't get all of the header bytes from this input.
            // Save in headerBuffer.
            if (headerLength_ + nRemainingBytes > headerBuffer_.len())
              // We don't expect this to happen.
              throw "Cannot store more header bytes than the size of headerBuffer";
            input.slice(offset_, offset_ + nRemainingBytes).copy
              (headerBuffer_, headerLength_);
            offset_ += nRemainingBytes;
            headerLength_ += nRemainingBytes;

            return false;
          }

          // Copy the remaining bytes into headerBuffer, read the
          //   length and set nBytesToRead.
          if (headerLength_ + nNeededBytes > headerBuffer_.len())
            // We don't expect this to happen.
            throw "Cannot store more header bytes than the size of headerBuffer";
          input.slice(offset_, offset_ + nNeededBytes).copy
            (headerBuffer_, headerLength_);
          offset_ += nNeededBytes;

          // Use a local decoder just for the headerBuffer.
          local bufferDecoder = TlvDecoder(headerBuffer_);
          // Replace nBytesToRead with the length of the value.
          nBytesToRead_ = bufferDecoder.readExtendedVarNumber_(firstOctet_);
        }

        if (nBytesToRead_ == 0) {
          // No value bytes to read. We're finished.
          gotElementEnd_ = true;
          return true;
        }

        // Get ready to read the value bytes.
        state_ = TlvStructureDecoder_READ_VALUE_BYTES;
      }
      else if (state_ == TlvStructureDecoder_READ_VALUE_BYTES) {
        local nRemainingBytes = input.len() - offset_;
        if (nRemainingBytes < nBytesToRead_) {
          // Need more.
          offset_ += nRemainingBytes;
          nBytesToRead_ -= nRemainingBytes;
          return false;
        }

        // Got the bytes. We're finished.
        offset_ += nBytesToRead_;
        gotElementEnd_ = true;
        return true;
      }
      else
        // We don't expect this to happen.
        throw "Unrecognized state";
    }
  }

  /**
   * Get the current offset into the input buffer.
   * @return {integer} The offset.
   */
  function getOffset() { return offset_; }

  /**
   * Set the offset into the input, used for the next read.
   * @param {integer} offset The new offset.
   */
  function seek(offset) { offset_ = offset; }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * An ElementReader lets you call onReceivedData multiple times which uses a
 * TlvStructureDecoder to detect the end of a TLV element and calls
 * elementListener.onReceivedElement(element) with the element.  This handles
 * the case where a single call to onReceivedData may contain multiple elements.
 */
class ElementReader {
  elementListener_ = null;
  dataParts_ = null;
  tlvStructureDecoder_ = null;

  /**
   * Create a new ElementReader with the elementListener.
   * @param {instance} elementListener An object with an onReceivedElement
   * method.
   */
  constructor(elementListener)
  {
    elementListener_ = elementListener;
    dataParts_ = [];
    tlvStructureDecoder_ = TlvStructureDecoder();
  }

  /**
   * Continue to read data until the end of an element, then call
   * elementListener_.onReceivedElement(element). The Buffer passed to
   * onReceivedElement is only valid during this call.  If you need the data
   * later, you must copy.
   * @param {Buffer} data The Buffer with the incoming element's bytes.
   */
  function onReceivedData(data)
  {
    // Process multiple elements in the data.
    while (true) {
      local gotElementEnd;
      local offset;

      try {
        if (dataParts_.len() == 0) {
          // This is the beginning of an element.
          if (data.len() <= 0)
            // Wait for more data.
            return;
        }

        // Scan the input to check if a whole TLV element has been read.
        tlvStructureDecoder_.seek(0);
        gotElementEnd = tlvStructureDecoder_.findElementEnd(data);
        offset = tlvStructureDecoder_.getOffset();
      } catch (ex) {
        // Reset to read a new element on the next call.
        dataParts_ = [];
        tlvStructureDecoder_ = TlvStructureDecoder();

        throw ex;
      }

      if (gotElementEnd) {
        // Got the remainder of an element.  Report to the caller.
        local element;
        if (dataParts_.len() == 0)
          element = data.slice(0, offset);
        else {
          dataParts_.push(data.slice(0, offset));
          element = Buffer.concat(dataParts_);
          dataParts_ = [];
        }

        // Reset to read a new element. Do this before calling onReceivedElement
        // in case it throws an exception.
        data = data.slice(offset, data.len());
        tlvStructureDecoder_ = TlvStructureDecoder();

        elementListener_.onReceivedElement(element);
        if (data.len() == 0)
          // No more data in the packet.
          return;

        // else loop back to decode.
      }
      else {
        // Save a copy. We will call concat later.
        local totalLength = data.len();
        for (local i = 0; i < dataParts_.len(); ++i)
          totalLength += dataParts_[i].len();
        if (totalLength > NdnCommon.MAX_NDN_PACKET_SIZE) {
          // Reset to read a new element on the next call.
          dataParts_ = [];
          tlvStructureDecoder_ = TlvStructureDecoder();

          throw "The incoming packet exceeds the maximum limit Face.getMaxNdnPacketSize()";
        }

        dataParts_.push(Buffer(data));
        return;
      }
    }
  }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * WireFormat is an abstract base class for encoding and decoding Interest,
 * Data, etc. with a specific wire format. You should use a derived class such
 * as TlvWireFormat.
 */
class WireFormat {
  /**
   * Set the static default WireFormat used by default encoding and decoding
   * methods.
   * @param {WireFormat} wireFormat An object of a subclass of WireFormat.
   */
  static function setDefaultWireFormat(wireFormat)
  {
    ::WireFormat_defaultWireFormat = wireFormat;
  }

  /**
   * Return the default WireFormat used by default encoding and decoding methods
   * which was set with setDefaultWireFormat.
   * @return {WireFormat} An object of a subclass of WireFormat.
   */
  static function getDefaultWireFormat()
  {
    return WireFormat_defaultWireFormat;
  }
}

// We use a global variable because static member variables are immutable.
WireFormat_defaultWireFormat <- null;
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * A Tlv0_2WireFormat extends WireFormat and has methods for encoding and
 * decoding with the NDN-TLV wire format, version 0.2.
 */
class Tlv0_2WireFormat extends WireFormat {
  /**
   * Encode interest as NDN-TLV and return the encoding.
   * @param {Name} name The Name to encode.
   * @return {Blobl} A Blob containing the encoding.
   */
  function encodeName(name)
  {
    local encoder = TlvEncoder(100);
    encodeName_(name, encoder);
    return encoder.finish();
  }

  /**
   * Decode input as an NDN-TLV name and set the fields of the Name object.
   * @param {Name} name The Name object whose fields are updated.
   * @param {Buffer} input The Buffer with the bytes to decode.
   * @param {bool} copy (optional) If true, copy from the input when making new
   * Blob values. If false, then Blob values share memory with the input, which
   * must remain unchanged while the Blob values are used. If omitted, use true.
   */
  function decodeName(name, input, copy = true)
  {
    local decoder = TlvDecoder(input);
    decodeName_(name, decoder, copy);
  }

  /**
   * Encode interest as NDN-TLV and return the encoding and signed offsets.
   * @param {Interest} interest The Interest object to encode.
   * @return {table} A table with fields (encoding, signedPortionBeginOffset,
   * signedPortionEndOffset) where encoding is a Blob containing the encoding,
   * signedPortionBeginOffset is the offset in the encoding of the beginning of
   * the signed portion, and signedPortionEndOffset is the offset in the
   * encoding of the end of the signed portion. The signed portion starts from
   * the first name component and ends just before the final name component
   * (which is assumed to be a signature for a signed interest).
   */
  function encodeInterest(interest)
  {
    local encoder = TlvEncoder(100);
    local saveLength = encoder.getLength();

    // Encode backwards.
/* TODO: Link.
    encoder.writeOptionalNonNegativeIntegerTlv
      (Tlv.SelectedDelegation, interest.getSelectedDelegationIndex());
    local linkWireEncoding = interest.getLinkWireEncoding(this);
    if (!linkWireEncoding.isNull())
      // Encode the entire link as is.
      encoder.writeBuffer(linkWireEncoding.buf());
*/

    encoder.writeOptionalNonNegativeIntegerTlvFromFloat
      (Tlv.InterestLifetime, interest.getInterestLifetimeMilliseconds());

    // Encode the Nonce as 4 bytes.
    if (interest.getNonce().size() == 0)
    {
      // This is the most common case. Generate a nonce.
      local nonce = Buffer(4);
      Crypto.generateRandomBytes(nonce);
      encoder.writeBlobTlv(Tlv.Nonce, nonce);
    }
    else if (interest.getNonce().size() < 4) {
      local nonce = Buffer(4);
      // Copy existing nonce bytes.
      interest.getNonce().buf().copy(nonce);

      // Generate random bytes for remaining bytes in the nonce.
      Crypto.generateRandomBytes(nonce.slice(interest.getNonce().size()));
      encoder.writeBlobTlv(Tlv.Nonce, nonce);
    }
    else if (interest.getNonce().size() == 4)
      // Use the nonce as-is.
      encoder.writeBlobTlv(Tlv.Nonce, interest.getNonce().buf());
    else
      // Truncate.
      encoder.writeBlobTlv(Tlv.Nonce, interest.getNonce().buf().slice(0, 4));

    encodeSelectors_(interest, encoder);
    local tempOffsets = encodeName_(interest.getName(), encoder);
    local signedPortionBeginOffsetFromBack =
      encoder.getLength() - tempOffsets.signedPortionBeginOffset;
    local signedPortionEndOffsetFromBack =
      encoder.getLength() - tempOffsets.signedPortionEndOffset;

    encoder.writeTypeAndLength(Tlv.Interest, encoder.getLength() - saveLength);
    local signedPortionBeginOffset =
      encoder.getLength() - signedPortionBeginOffsetFromBack;
    local signedPortionEndOffset =
      encoder.getLength() - signedPortionEndOffsetFromBack;

    return { encoding = encoder.finish(),
             signedPortionBeginOffset = signedPortionBeginOffset,
             signedPortionEndOffset = signedPortionEndOffset };
  }

  /**
   * Decode input as an NDN-TLV interest packet, set the fields in the interest
   * object, and return the signed offsets.
   * @param {Interest} interest The Interest object whose fields are updated.
   * @param {Buffer} input The Buffer with the bytes to decode.
   * @param {bool} copy (optional) If true, copy from the input when making new
   * Blob values. If false, then Blob values share memory with the input, which
   * must remain unchanged while the Blob values are used. If omitted, use true.
   * @return {table} A table with fields (signedPortionBeginOffset,
   * signedPortionEndOffset) where signedPortionBeginOffset is the offset in the
   * encoding of the beginning of the signed portion, and signedPortionEndOffset
   * is the offset in the encoding of the end of the signed portion. The signed
   * portion starts from the first name component and ends just before the final
   * name component (which is assumed to be a signature for a signed interest).
   */
  function decodeInterest(interest, input, copy = true)
  {
    local decoder = TlvDecoder(input);

    local endOffset = decoder.readNestedTlvsStart(Tlv.Interest);
    local offsets = decodeName_(interest.getName(), decoder, copy);
    if (decoder.peekType(Tlv.Selectors, endOffset))
      decodeSelectors_(interest, decoder, copy);
    // Require a Nonce, but don't force it to be 4 bytes.
    local nonce = decoder.readBlobTlv(Tlv.Nonce);
    interest.setInterestLifetimeMilliseconds
      (decoder.readOptionalNonNegativeIntegerTlv(Tlv.InterestLifetime, endOffset));

/* TODO Link.
    if (decoder.peekType(Tlv.Data, endOffset)) {
      // Get the bytes of the Link TLV.
      local linkBeginOffset = decoder.getOffset();
      local linkEndOffset = decoder.readNestedTlvsStart(Tlv.Data);
      decoder.seek(linkEndOffset);

      interest.setLinkWireEncoding
        (Blob(decoder.getSlice(linkBeginOffset, linkEndOffset), copy), this);
    }
    else
      interest.unsetLink();
    interest.setSelectedDelegationIndex
      (decoder.readOptionalNonNegativeIntegerTlv(Tlv.SelectedDelegation, endOffset));
    if (interest.getSelectedDelegationIndex() != null &&
        interest.getSelectedDelegationIndex() >= 0 && !interest.hasLink())
      throw "Interest has a selected delegation, but no link object";
*/

    // Set the nonce last because setting other interest fields clears it.
    interest.setNonce(Blob(nonce, copy));

    decoder.finishNestedTlvs(endOffset);
    return offsets;
  }

  /**
   * Encode data as NDN-TLV and return the encoding and signed offsets.
   * @param {Data} data The Data object to encode.
   * @return {table} A table with fields (encoding, signedPortionBeginOffset,
   * signedPortionEndOffset) where encoding is a Blob containing the encoding,
   * signedPortionBeginOffset is the offset in the encoding of the beginning of
   * the signed portion, and signedPortionEndOffset is the offset in the
   * encoding of the end of the signed portion.
   */
  function encodeData(data)
  {
    local encoder = TlvEncoder(500);
    local saveLength = encoder.getLength();

    // Encode backwards.
    encoder.writeBlobTlv
      (Tlv.SignatureValue, data.getSignature().getSignature().buf());
    local signedPortionEndOffsetFromBack = encoder.getLength();

    encodeSignatureInfo_(data.getSignature(), encoder);
    encoder.writeBlobTlv(Tlv.Content, data.getContent().buf());
    encodeMetaInfo_(data.getMetaInfo(), encoder);
    encodeName_(data.getName(), encoder);
    local signedPortionBeginOffsetFromBack = encoder.getLength();

    encoder.writeTypeAndLength(Tlv.Data, encoder.getLength() - saveLength);
    local signedPortionBeginOffset =
      encoder.getLength() - signedPortionBeginOffsetFromBack;
    local signedPortionEndOffset =
      encoder.getLength() - signedPortionEndOffsetFromBack;

    return { encoding = encoder.finish(),
             signedPortionBeginOffset = signedPortionBeginOffset,
             signedPortionEndOffset = signedPortionEndOffset };
  }

  /**
   * Decode input as an NDN-TLV data packet, set the fields in the data object,
   * and return the signed offsets.
   * @param {Data} data The Data object whose fields are updated.
   * @param {Buffer} input The Buffer with the bytes to decode.
   * @param {bool} copy (optional) If true, copy from the input when making new
   * Blob values. If false, then Blob values share memory with the input, which
   * must remain unchanged while the Blob values are used. If omitted, use true.
   * @return {table} A table with fields (signedPortionBeginOffset,
   * signedPortionEndOffset) where signedPortionBeginOffset is the offset in the
   * encoding of the beginning of the signed portion, and signedPortionEndOffset
   * is the offset in the encoding of the end of the signed portion.
   */
  function decodeData(data, input, copy = true)
  {
    local decoder = TlvDecoder(input);

    local endOffset = decoder.readNestedTlvsStart(Tlv.Data);
    local signedPortionBeginOffset = decoder.getOffset();

    decodeName_(data.getName(), decoder, copy);
    decodeMetaInfo_(data.getMetaInfo(), decoder, copy);
    data.setContent(Blob(decoder.readBlobTlv(Tlv.Content), copy));
    decodeSignatureInfo_(data, decoder, copy);

    local signedPortionEndOffset = decoder.getOffset();
    data.getSignature().setSignature
      (Blob(decoder.readBlobTlv(Tlv.SignatureValue), copy));

    decoder.finishNestedTlvs(endOffset);
    return { signedPortionBeginOffset = signedPortionBeginOffset,
             signedPortionEndOffset = signedPortionEndOffset };
  }

  /**
   * Encode signature as an NDN-TLV SignatureInfo and return the encoding.
   * @param {Signature} signature An object of a subclass of Signature to encode.
   * @return {Blob} A Blob containing the encoding.
   */
  function encodeSignatureInfo(signature)
  {
    local encoder = TlvEncoder(100);
    encodeSignatureInfo_(signature, encoder);
    return encoder.finish();
  }

  /**
   * Encode the signatureValue in the Signature object as an NDN-TLV
   * SignatureValue (the signature bits) and return the encoding.
   * @param {Signature} signature An object of a subclass of Signature with the
   * signature value to encode.
   * @return {Blob} A Blob containing the encoding.
   */
  function encodeSignatureValue(signature)
  {
    local encoder = TlvEncoder(100);
    encoder.writeBlobTlv(Tlv.SignatureValue, signature.getSignature().buf());
    return encoder.finish();
  }

  /**
   * Decode signatureInfo as an NDN-TLV SignatureInfo and signatureValue as the
   * related SignatureValue, and return a new object which is a subclass of
   * Signature.
   * @param {Buffer} signatureInfo The Buffer with the SignatureInfo bytes to
   * decode.
   * @param {Buffer} signatureValue The Buffer with the SignatureValue bytes to
   * decode.
   * @param {bool} copy (optional) If true, copy from the input when making new
   * Blob values. If false, then Blob values share memory with the input, which
   * must remain unchanged while the Blob values are used. If omitted, use true.
   * @return {Signature} A new object which is a subclass of Signature.
   */
  function decodeSignatureInfoAndValue(signatureInfo, signatureValue, copy = true)
  {
    // Use a SignatureHolder to imitate a Data object for decodeSignatureInfo_.
    local signatureHolder = Tlv0_2WireFormat_SignatureHolder();
    local decoder = TlvDecoder(signatureInfo);
    decodeSignatureInfo_(signatureHolder, decoder, copy);

    decoder = TlvDecoder(signatureValue);
    signatureHolder.getSignature().setSignature
      (Blob(decoder.readBlobTlv(Tlv.SignatureValue), copy));

    return signatureHolder.getSignature();
  }

  /**
   * Decode input as an NDN-TLV LpPacket and set the fields of the lpPacket
   * object.
   * @param {LpPacket} lpPacket The LpPacket object whose fields are updated.
   * @param {Buffer} input The Buffer with the bytes to decode.
   * @param {bool} copy (optional) If true, copy from the input when making new
   * Blob values. If false, then Blob values share memory with the input, which
   * must remain unchanged while the Blob values are used. If omitted, use true.
   */
  function decodeLpPacket(lpPacket, input, copy = true)
  {
    lpPacket.clear();

    local decoder = TlvDecoder(input);
    local endOffset = decoder.readNestedTlvsStart(Tlv.LpPacket_LpPacket);

    while (decoder.getOffset() < endOffset) {
      // Imitate TlvDecoder.readTypeAndLength.
      local fieldType = decoder.readVarNumber();
      local fieldLength = decoder.readVarNumber();
      local fieldEndOffset = decoder.getOffset() + fieldLength;
      if (fieldEndOffset > input.length)
        throw "TLV length exceeds the buffer length";

      if (fieldType == Tlv.LpPacket_Fragment) {
        // Set the fragment to the bytes of the TLV value.
        lpPacket.setFragmentWireEncoding
          (Blob(decoder.getSlice(decoder.getOffset(), fieldEndOffset), copy));
        decoder.seek(fieldEndOffset);

        // The fragment is supposed to be the last field.
        break;
      }
/**   TODO: Support Nack and IncomingFaceid
      else if (fieldType == Tlv.LpPacket_Nack) {
        local networkNack = NetworkNack();
        local code = decoder.readOptionalNonNegativeIntegerTlv
          (Tlv.LpPacket_NackReason, fieldEndOffset);
        local reason;
        // The enum numeric values are the same as this wire format, so use as is.
        if (code < 0 || code == NetworkNack.Reason.NONE)
          // This includes an omitted NackReason.
          networkNack.setReason(NetworkNack.Reason.NONE);
        else if (code == NetworkNack.Reason.CONGESTION ||
                 code == NetworkNack.Reason.DUPLICATE ||
                 code == NetworkNack.Reason.NO_ROUTE)
          networkNack.setReason(code);
        else {
          // Unrecognized reason.
          networkNack.setReason(NetworkNack.Reason.OTHER_CODE);
          networkNack.setOtherReasonCode(code);
        }

        lpPacket.addHeaderField(networkNack);
      }
      else if (fieldType == Tlv.LpPacket_IncomingFaceId) {
        local incomingFaceId = new IncomingFaceId();
        incomingFaceId.setFaceId(decoder.readNonNegativeInteger(fieldLength));
        lpPacket.addHeaderField(incomingFaceId);
      }
*/
      else {
        // Unrecognized field type. The conditions for ignoring are here:
        // http://redmine.named-data.net/projects/nfd/wiki/NDNLPv2
        local canIgnore =
          (fieldType >= Tlv.LpPacket_IGNORE_MIN &&
           fieldType <= Tlv.LpPacket_IGNORE_MAX &&
           (fieldType & 0x01) == 1);
        if (!canIgnore)
          throw "Did not get the expected TLV type";

        // Ignore.
        decoder.seek(fieldEndOffset);
      }

      decoder.finishNestedTlvs(fieldEndOffset);
    }

    decoder.finishNestedTlvs(endOffset);
  }

  /**
   * Encode the EncryptedContent in NDN-TLV and return the encoding.
   * @param {EncryptedContent} encryptedContent The EncryptedContent object to
   * encode.
   * @return {Blobl} A Blob containing the encoding.
   */
  function encodeEncryptedContent(encryptedContent)
  {
    local encoder = TlvEncoder(100);
    local saveLength = encoder.getLength();

    // Encode backwards.
    encoder.writeBlobTlv
      (Tlv.Encrypt_EncryptedPayload, encryptedContent.getPayload().buf());
    encoder.writeOptionalBlobTlv
      (Tlv.Encrypt_InitialVector, encryptedContent.getInitialVector().buf());
    // Assume the algorithmType value is the same as the TLV type.
    encoder.writeNonNegativeIntegerTlv
      (Tlv.Encrypt_EncryptionAlgorithm, encryptedContent.getAlgorithmType());
    Tlv0_2WireFormat.encodeKeyLocator_
      (Tlv.KeyLocator, encryptedContent.getKeyLocator(), encoder);

    encoder.writeTypeAndLength
      (Tlv.Encrypt_EncryptedContent, encoder.getLength() - saveLength);

    return encoder.finish();
  }

  /**
   * Decode input as an EncryptedContent in NDN-TLV and set the fields of the
   * encryptedContent object.
   * @param {EncryptedContent} encryptedContent The EncryptedContent object
   * whose fields are updated.
   * @param {Buffer} input The Buffer with the bytes to decode.
   * @param {bool} copy (optional) If true, copy from the input when making new
   * Blob values. If false, then Blob values share memory with the input, which
   * must remain unchanged while the Blob values are used. If omitted, use true.
   */
  function decodeEncryptedContent(encryptedContent, input, copy = true)
  {
    local decoder = TlvDecoder(input);
    local endOffset = decoder.
      readNestedTlvsStart(Tlv.Encrypt_EncryptedContent);

    Tlv0_2WireFormat.decodeKeyLocator_
      (Tlv.KeyLocator, encryptedContent.getKeyLocator(), decoder, copy);
    encryptedContent.setAlgorithmType
      (decoder.readNonNegativeIntegerTlv(Tlv.Encrypt_EncryptionAlgorithm));
    encryptedContent.setInitialVector
      (Blob(decoder.readOptionalBlobTlv
       (Tlv.Encrypt_InitialVector, endOffset), copy));
    encryptedContent.setPayload
      (Blob(decoder.readBlobTlv(Tlv.Encrypt_EncryptedPayload), copy));

    decoder.finishNestedTlvs(endOffset);
  }

  /**
   * Get a singleton instance of a Tlv0_2WireFormat.  To always use the
   * preferred version NDN-TLV, you should use TlvWireFormat.get().
   * @return {Tlv0_2WireFormat} The singleton instance.
   */
  static function get()
  {
    if (Tlv0_2WireFormat_instance == null)
      ::Tlv0_2WireFormat_instance = Tlv0_2WireFormat();
    return Tlv0_2WireFormat_instance;
  }

  /**
   * Encode the name component to the encoder as NDN-TLV. This handles different
   * component types such as ImplicitSha256DigestComponent.
   * @param {NameComponent} component The name component to encode.
   * @param {TlvEncoder} encoder The TlvEncoder which receives the encoding.
   */
  static function encodeNameComponent_(component, encoder)
  {
    local type = component.isImplicitSha256Digest() ?
      Tlv.ImplicitSha256DigestComponent : Tlv.NameComponent;
    encoder.writeBlobTlv(type, component.getValue().buf());
  }

  /**
   * Decode the name component as NDN-TLV and return the component. This handles
   * different component types such as ImplicitSha256DigestComponent.
   * @param {TlvDecoder} decoder The decoder with the input.
   * @param {bool} copy If true, copy from the input when making new Blob
   * values. If false, then Blob values share memory with the input, which must
   * remain unchanged while the Blob values are used.
   */
  static function decodeNameComponent_(decoder, copy)
  {
    local savePosition = decoder.getOffset();
    local type = decoder.readVarNumber();
    // Restore the position.
    decoder.seek(savePosition);

    local value = Blob(decoder.readBlobTlv(type), copy);
    if (type == Tlv.ImplicitSha256DigestComponent)
      return NameComponent.fromImplicitSha256Digest(value);
    else
      return NameComponent(value);
  }

  /**
   * Encode the name to the encoder.
   * @param {Name} name The name to encode.
   * @param {TlvEncoder} encoder The encoder to receive the encoding.
   * @return {table} A table with fields signedPortionBeginOffset and
   * signedPortionEndOffset where signedPortionBeginOffset is the offset in the
   * encoding of the beginning of the signed portion, and signedPortionEndOffset
   * is the offset in the encoding of the end of the signed portion. The signed
   * portion starts from the first name component and ends just before the final
   * name component (which is assumed to be a signature for a signed interest).
   */
  static function encodeName_(name, encoder)
  {
    local saveLength = encoder.getLength();

    // Encode the components backwards.
    local signedPortionEndOffsetFromBack;
    for (local i = name.size() - 1; i >= 0; --i) {
      encodeNameComponent_(name.get(i), encoder);
      if (i == name.size() - 1)
        signedPortionEndOffsetFromBack = encoder.getLength();
    }

    local signedPortionBeginOffsetFromBack = encoder.getLength();
    encoder.writeTypeAndLength(Tlv.Name, encoder.getLength() - saveLength);

    local signedPortionBeginOffset =
      encoder.getLength() - signedPortionBeginOffsetFromBack;
    local signedPortionEndOffset;
    if (name.size() == 0)
      // There is no "final component", so set signedPortionEndOffset arbitrarily.
      signedPortionEndOffset = signedPortionBeginOffset;
    else
      signedPortionEndOffset = encoder.getLength() - signedPortionEndOffsetFromBack;

    return { signedPortionBeginOffset = signedPortionBeginOffset,
             signedPortionEndOffset = signedPortionEndOffset };
  }

  /**
   * Clear the name, decode a Name from the decoder and set the fields of the
   * name object.
   * @param {Name} name The name object whose fields are updated.
   * @param {TlvDecoder} decoder The decoder with the input.
   * @param {bool} copy If true, copy from the input when making new Blob
   * values. If false, then Blob values share memory with the input, which must
   * remain unchanged while the Blob values are used.
   * @return {table} A table with fields signedPortionBeginOffset and
   * signedPortionEndOffset where signedPortionBeginOffset is the offset in the
   * encoding of the beginning of the signed portion, and signedPortionEndOffset
   * is the offset in the encoding of the end of the signed portion. The signed
   * portion starts from the first name component and ends just before the final
   * name component (which is assumed to be a signature for a signed interest).
   */
  static function decodeName_(name, decoder, copy)
  {
    name.clear();

    local endOffset = decoder.readNestedTlvsStart(Tlv.Name);
    local signedPortionBeginOffset = decoder.getOffset();
    // In case there are no components, set signedPortionEndOffset arbitrarily.
    local signedPortionEndOffset = signedPortionBeginOffset;

    while (decoder.getOffset() < endOffset) {
      signedPortionEndOffset = decoder.getOffset();
      name.append(decodeNameComponent_(decoder, copy));
    }

    decoder.finishNestedTlvs(endOffset);

    return { signedPortionBeginOffset = signedPortionBeginOffset,
             signedPortionEndOffset = signedPortionEndOffset };
  }

  /**
   * An internal method to encode the interest Selectors in NDN-TLV. If no
   * selectors are written, do not output a Selectors TLV.
   * @param {Interest} interest The Interest object with the selectors to encode.
   * @param {TlvEncoder} encoder The encoder to receive the encoding.
   */
  static function encodeSelectors_(interest, encoder)
  {
    local saveLength = encoder.getLength();

    // Encode backwards.
    if (interest.getMustBeFresh())
      encoder.writeTypeAndLength(Tlv.MustBeFresh, 0);
    // else MustBeFresh == false, so nothing to encode.
    encoder.writeOptionalNonNegativeIntegerTlv
      (Tlv.ChildSelector, interest.getChildSelector());
    if (interest.getExclude().size() > 0)
      encodeExclude_(interest.getExclude(), encoder);

    if (interest.getKeyLocator().getType() != null)
      encodeKeyLocator_
        (Tlv.PublisherPublicKeyLocator, interest.getKeyLocator(), encoder);

    encoder.writeOptionalNonNegativeIntegerTlv
      (Tlv.MaxSuffixComponents, interest.getMaxSuffixComponents());
    encoder.writeOptionalNonNegativeIntegerTlv
      (Tlv.MinSuffixComponents, interest.getMinSuffixComponents());

    // Only output the type and length if values were written.
    if (encoder.getLength() != saveLength)
      encoder.writeTypeAndLength(Tlv.Selectors, encoder.getLength() - saveLength);
  }

  /**
   * Decode an NDN-TLV Selectors from the decoder and set the fields of
   * the Interest object.
   * @param {Interest} interest The Interest object whose fields are
   * updated.
   * @param {TlvDecoder} decoder The decoder with the input.
   * @param {bool} copy If true, copy from the input when making new Blob
   * values. If false, then Blob values share memory with the input, which must
   * remain unchanged while the Blob values are used.
   */
  static function decodeSelectors_(interest, decoder, copy)
  {
    local endOffset = decoder.readNestedTlvsStart(Tlv.Selectors);

    interest.setMinSuffixComponents(decoder.readOptionalNonNegativeIntegerTlv
      (Tlv.MinSuffixComponents, endOffset));
    interest.setMaxSuffixComponents(decoder.readOptionalNonNegativeIntegerTlv
      (Tlv.MaxSuffixComponents, endOffset));

    if (decoder.peekType(Tlv.PublisherPublicKeyLocator, endOffset))
      decodeKeyLocator_
        (Tlv.PublisherPublicKeyLocator, interest.getKeyLocator(), decoder, copy);
    else
      interest.getKeyLocator().clear();

    if (decoder.peekType(Tlv.Exclude, endOffset))
      decodeExclude_(interest.getExclude(), decoder, copy);
    else
      interest.getExclude().clear();

    interest.setChildSelector(decoder.readOptionalNonNegativeIntegerTlv
      (Tlv.ChildSelector, endOffset));
    interest.setMustBeFresh(decoder.readBooleanTlv(Tlv.MustBeFresh, endOffset));

    decoder.finishNestedTlvs(endOffset);
  }

  /**
   * An internal method to encode exclude as an Exclude in NDN-TLV.
   * @param {Exclude} exclude The Exclude object.
   * @param {TlvEncoder} encoder The encoder to receive the encoding.
   */
  static function encodeExclude_(exclude, encoder)
  {
    local saveLength = encoder.getLength();

    // TODO: Do we want to order the components (except for ANY)?
    // Encode the entries backwards.
    for (local i = exclude.size() - 1; i >= 0; --i) {
      local entry = exclude.get(i);

      if (entry.getType() == ExcludeType.COMPONENT)
        encodeNameComponent_(entry.getComponent(), encoder);
      else if (entry.getType() == ExcludeType.ANY)
        encoder.writeTypeAndLength(Tlv.Any, 0);
      else
        throw "Unrecognized ExcludeType";
    }

    encoder.writeTypeAndLength(Tlv.Exclude, encoder.getLength() - saveLength);
  }

  /**
   * Clear the exclude, decode an NDN-TLV Exclude from the decoder and set the
   * fields of the Exclude object.
   * @param {Exclude} exclude The Exclude object whose fields are
   * updated.
   * @param {TlvDecoder} decoder The decoder with the input.
   * @param {bool} copy If true, copy from the input when making new Blob
   * values. If false, then Blob values share memory with the input, which must
   * remain unchanged while the Blob values are used.
   */
  static function decodeExclude_(exclude, decoder, copy)
  {
    local endOffset = decoder.readNestedTlvsStart(Tlv.Exclude);

    exclude.clear();
    while (decoder.getOffset() < endOffset) {
      if (decoder.peekType(Tlv.Any, endOffset)) {
        // Read past the Any TLV.
        decoder.readBooleanTlv(Tlv.Any, endOffset);
        exclude.appendAny();
      }
      else
        exclude.appendComponent(decodeNameComponent_(decoder, copy));
    }

    decoder.finishNestedTlvs(endOffset);
  }

  /**
   * An internal method to encode keyLocator as a KeyLocator in NDN-TLV with the
   * given type.
   * @param {integer} type The type for the TLV.
   * @param {KeyLocator} keyLocator The KeyLocator object.
   * @param {TlvEncoder} encoder The encoder to receive the encoding.
   */
  static function encodeKeyLocator_(type, keyLocator, encoder)
  {
    local saveLength = encoder.getLength();

    // Encode backwards.
    if (keyLocator.getType() == KeyLocatorType.KEYNAME)
      encodeName_(keyLocator.getKeyName(), encoder);
    else if (keyLocator.getType() == KeyLocatorType.KEY_LOCATOR_DIGEST &&
             keyLocator.getKeyData().size() > 0)
      encoder.writeBlobTlv(Tlv.KeyLocatorDigest, keyLocator.getKeyData().buf());
    else
      throw "Unrecognized KeyLocator type ";

    encoder.writeTypeAndLength(type, encoder.getLength() - saveLength);
  }

  /**
   * Clear the name, decode a KeyLocator from the decoder and set the fields of
   * the keyLocator object.
   * @param {integer} expectedType The expected type of the TLV.
   * @param {KeyLocator} keyLocator The KeyLocator object whose fields are
   * updated.
   * @param {TlvDecoder} decoder The decoder with the input.
   * @param {bool} copy If true, copy from the input when making new Blob
   * values. If false, then Blob values share memory with the input, which must
   * remain unchanged while the Blob values are used.
   */
  static function decodeKeyLocator_(expectedType, keyLocator, decoder, copy)
  {
    local endOffset = decoder.readNestedTlvsStart(expectedType);

    keyLocator.clear();

    if (decoder.getOffset() == endOffset)
      // The KeyLocator is omitted, so leave the fields as none.
      return;

    if (decoder.peekType(Tlv.Name, endOffset)) {
      // KeyLocator is a Name.
      keyLocator.setType(KeyLocatorType.KEYNAME);
      decodeName_(keyLocator.getKeyName(), decoder, copy);
    }
    else if (decoder.peekType(Tlv.KeyLocatorDigest, endOffset)) {
      // KeyLocator is a KeyLocatorDigest.
      keyLocator.setType(KeyLocatorType.KEY_LOCATOR_DIGEST);
      keyLocator.setKeyData(Blob(decoder.readBlobTlv(Tlv.KeyLocatorDigest), copy));
    }
    else
      throw "decodeKeyLocator: Unrecognized key locator type";

    decoder.finishNestedTlvs(endOffset);
  }
  
  /**
   * An internal method to encode signature as the appropriate form of
   * SignatureInfo in NDN-TLV.
   * @param {Signature} signature An object of a subclass of Signature.
   * @param {TlvEncoder} encoder The encoder to receive the encoding.
   */
  static function encodeSignatureInfo_(signature, encoder)
  {
    if (signature instanceof GenericSignature) {
      // Handle GenericSignature separately since it has the entire encoding.
      local encoding = signature.getSignatureInfoEncoding();

      // Do a test decoding to sanity check that it is valid TLV.
      try {
        local decoder = TlvDecoder(encoding.buf());
        local endOffset = decoder.readNestedTlvsStart(Tlv.SignatureInfo);
        decoder.readNonNegativeIntegerTlv(Tlv.SignatureType);
        decoder.finishNestedTlvs(endOffset);
      } catch (ex) {
        throw
          "The GenericSignature encoding is not a valid NDN-TLV SignatureInfo: " +
           ex;
      }

      encoder.writeBuffer(encoding.buf());
      return;
    }

    local saveLength = encoder.getLength();

    // Encode backwards.
    if (signature instanceof Sha256WithRsaSignature) {
      encodeKeyLocator_
        (Tlv.KeyLocator, signature.getKeyLocator(), encoder);
      encoder.writeNonNegativeIntegerTlv
        (Tlv.SignatureType, Tlv.SignatureType_SignatureSha256WithRsa);
    }
    // TODO: Sha256WithEcdsaSignature.
    else if (signature instanceof HmacWithSha256Signature) {
      encodeKeyLocator_
        (Tlv.KeyLocator, signature.getKeyLocator(), encoder);
      encoder.writeNonNegativeIntegerTlv
        (Tlv.SignatureType, Tlv.SignatureType_SignatureHmacWithSha256);
    }
    // TODO: DigestSha256Signature.
    else
      throw "encodeSignatureInfo: Unrecognized Signature object type";

    encoder.writeTypeAndLength
      (Tlv.SignatureInfo, encoder.getLength() - saveLength);
  }

  /**
   * Decode an NDN-TLV SignatureInfo from the decoder and set the Data object
   * with a new Signature object.
   * @param {Data} data This calls data.setSignature with a new Signature object.
   * @param {TlvDecoder} decoder The decoder with the input.
   * @param {bool} copy If true, copy from the input when making new Blob
   * values. If false, then Blob values share memory with the input, which must
   * remain unchanged while the Blob values are used.
   */
  static function decodeSignatureInfo_(data, decoder, copy)
  {
    local beginOffset = decoder.getOffset();
    local endOffset = decoder.readNestedTlvsStart(Tlv.SignatureInfo);

    local signatureType = decoder.readNonNegativeIntegerTlv(Tlv.SignatureType);
    if (signatureType == Tlv.SignatureType_SignatureSha256WithRsa) {
      data.setSignature(Sha256WithRsaSignature());
      // Modify data's signature object because if we create an object
      //   and set it, then data will have to copy all the fields.
      local signatureInfo = data.getSignature();
      decodeKeyLocator_
        (Tlv.KeyLocator, signatureInfo.getKeyLocator(), decoder, copy);
    }
    else if (signatureType == Tlv.SignatureType_SignatureHmacWithSha256) {
      data.setSignature(HmacWithSha256Signature());
      local signatureInfo = data.getSignature();
      decodeKeyLocator_
        (Tlv.KeyLocator, signatureInfo.getKeyLocator(), decoder, copy);
    }
    else if (signatureType == Tlv.SignatureType_DigestSha256)
      data.setSignature(DigestSha256Signature());
    else {
      data.setSignature(GenericSignature());
      local signatureInfo = data.getSignature();

      // Get the bytes of the SignatureInfo TLV.
      signatureInfo.setSignatureInfoEncoding
        (Blob(decoder.getSlice(beginOffset, endOffset), copy), signatureType);
    }

    decoder.finishNestedTlvs(endOffset);
  }

  /**
   * An internal method to encode metaInfo as a MetaInfo in NDN-TLV.
   * @param {MetaInfo} metaInfo The MetaInfo object.
   * @param {TlvEncoder} encoder The encoder to receive the encoding.
   */
  static function encodeMetaInfo_(metaInfo, encoder)
  {
    local saveLength = encoder.getLength();

    // Encode backwards.
    local finalBlockIdBuf = metaInfo.getFinalBlockId().getValue().buf();
    if (finalBlockIdBuf != null && finalBlockIdBuf.len() > 0) {
      // The FinalBlockId has an inner NameComponent.
      local finalBlockIdSaveLength = encoder.getLength();
      encodeNameComponent_(metaInfo.getFinalBlockId(), encoder);
      encoder.writeTypeAndLength
        (Tlv.FinalBlockId, encoder.getLength() - finalBlockIdSaveLength);
    }

    encoder.writeOptionalNonNegativeIntegerTlvFromFloat
      (Tlv.FreshnessPeriod, metaInfo.getFreshnessPeriod());
    if (!(metaInfo.getType() == null || metaInfo.getType() < 0 ||
          metaInfo.getType() == ContentType.BLOB)) {
      // Not the default, so we need to encode the type.
      if (metaInfo.getType() == ContentType.LINK ||
          metaInfo.getType() == ContentType.KEY ||
          metaInfo.getType() == ContentType.NACK)
        // The ContentType enum is set up with the correct integer for each
        // NDN-TLV ContentType.
        encoder.writeNonNegativeIntegerTlv(Tlv.ContentType, metaInfo.getType());
      else if (metaInfo.getType() == ContentType.OTHER_CODE)
        encoder.writeNonNegativeIntegerTlv
            (Tlv.ContentType, metaInfo.getOtherTypeCode());
      else
        // We don't expect this to happen.
        throw "Unrecognized ContentType";
    }

    encoder.writeTypeAndLength(Tlv.MetaInfo, encoder.getLength() - saveLength);
  }

  /**
   * Clear the name, decode a MetaInfo from the decoder and set the fields of
   * the metaInfo object.
   * @param {MetaInfo} metaInfo The MetaInfo object whose fields are updated.
   * @param {TlvDecoder} decoder The decoder with the input.
   * @param {bool} copy If true, copy from the input when making new Blob
   * values. If false, then Blob values share memory with the input, which must
   * remain unchanged while the Blob values are used.
   */
  static function decodeMetaInfo_(metaInfo, decoder, copy)
  {
    local endOffset = decoder.readNestedTlvsStart(Tlv.MetaInfo);

    local type = decoder.readOptionalNonNegativeIntegerTlv
      (Tlv.ContentType, endOffset);
    if (type == null || type < 0 || type == ContentType.BLOB)
      metaInfo.setType(ContentType.BLOB);
    else if (type == ContentType.LINK ||
             type == ContentType.KEY ||
             type == ContentType.NACK)
      // The ContentType enum is set up with the correct integer for each
      // NDN-TLV ContentType.
      metaInfo.setType(type);
    else {
      // Unrecognized content type.
      metaInfo.setType(ContentType.OTHER_CODE);
      metaInfo.setOtherTypeCode(type);
    }

    metaInfo.setFreshnessPeriod
      (decoder.readOptionalNonNegativeIntegerTlv(Tlv.FreshnessPeriod, endOffset));
    if (decoder.peekType(Tlv.FinalBlockId, endOffset)) {
      local finalBlockIdEndOffset = decoder.readNestedTlvsStart(Tlv.FinalBlockId);
      metaInfo.setFinalBlockId(decodeNameComponent_(decoder, copy));
      decoder.finishNestedTlvs(finalBlockIdEndOffset);
    }
    else
      metaInfo.setFinalBlockId(null);

    decoder.finishNestedTlvs(endOffset);
  }
}

// Tlv0_2WireFormat_SignatureHolder is used by decodeSignatureInfoAndValue.
class Tlv0_2WireFormat_SignatureHolder
{
  signature_ = null;

  function setSignature(signature) { signature_ = signature; }

  function getSignature() { return signature_; }
}

// We use a global variable because static member variables are immutable.
Tlv0_2WireFormat_instance <- null;
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * A TlvWireFormat extends WireFormat to override its methods to
 * implement encoding and decoding using the preferred implementation of NDN-TLV.
 */
class TlvWireFormat extends Tlv0_2WireFormat {
  /**
   * Get a singleton instance of a TlvWireFormat.  Assuming that the default
   * wire format was set with WireFormat.setDefaultWireFormat(TlvWireFormat.get()),
   * you can check if this is the default wire encoding with
   * if WireFormat.getDefaultWireFormat() == TlvWireFormat.get().
   * @return {TlvWireFormat} The singleton instance.
   */
  static function get()
  {
    if (TlvWireFormat_instance == null)
      ::TlvWireFormat_instance = TlvWireFormat();
    return TlvWireFormat_instance;
  }
}

// We use a global variable because static member variables are immutable.
TlvWireFormat_instance <- null;

// On loading this code, make this the default wire format.
WireFormat.setDefaultWireFormat(TlvWireFormat.get());
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

// These correspond to the TLV codes.
enum EncryptAlgorithmType {
  AesEcb = 0,
  AesCbc = 1,
  RsaPkcs = 2,
  RsaOaep = 3
}

/**
 * An EncryptParams holds an algorithm type and other parameters used to encrypt
 * and decrypt.
 */
class EncryptParams {
  algorithmType_ = 0;
  initialVector_ = null;

  /**
   * Create an EncryptParams with the given parameters.
   * @param {integer} algorithmType The algorithm type from the
   * EncryptAlgorithmType enum, or null if not specified.
   * @param {integer} initialVectorLength (optional) The initial vector length,
   * or 0 if the initial vector is not specified. If omitted, the initial
   * vector is not specified.
   * @note This class is an experimental feature. The API may change.
   */
  constructor(algorithmType, initialVectorLength = null)
  {
    algorithmType_ = algorithmType;

    if (initialVectorLength != null && initialVectorLength > 0) {
      local initialVector = Buffer(initialVectorLength);
      Crypto.generateRandomBytes(initialVector);
      initialVector_ = Blob(initialVector, false);
    }
    else
      initialVector_ = Blob();
  }

  /**
   * Get the algorithmType.
   * @return {integer} The algorithm type from the EncryptAlgorithmType enum,
   * or null if not specified.
   */
  function getAlgorithmType() { return algorithmType_; }

  /**
   * Get the initial vector.
   * @return {Blob} The initial vector. If not specified, isNull() is true.
   */
  function getInitialVector() { return initialVector_; }

  /**
   * Set the algorithm type.
   * @param {integer} algorithmType The algorithm type from the
   * EncryptAlgorithmType enum. If not specified, set to null.
   * @return {EncryptParams} This EncryptParams so that you can chain calls to
   * update values.
   */
  function setAlgorithmType(algorithmType)
  {
    algorithmType_ = algorithmType;
    return this;
  }

  /**
   * Set the initial vector.
   * @param {Blob} initialVector The initial vector. If not specified, set to
   * the default Blob() where isNull() is true.
   * @return {EncryptParams} This EncryptParams so that you can chain calls to
   * update values.
   */
  function setInitialVector(initialVector)
  {
    this.initialVector_ =
      initialVector instanceof Blob ? initialVector : Blob(initialVector, true);
    return this;
  }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

// This requires contrib/kisi-inc/aes-squirrel/aes.class.nut .

/**
 * The AesAlgorithm class provides static methods to manipulate keys, encrypt
 * and decrypt using the AES symmetric key cipher.
 * @note This class is an experimental feature. The API may change.
 */
class AesAlgorithm {
  static BLOCK_SIZE = 16;

  /**
   * Generate a new random decrypt key for AES based on the given params.
   * @param {AesKeyParams} params The key params with the key size (in bits).
   * @return {DecryptKey} The new decrypt key.
   */
  static function generateKey(params)
  {
    // Convert the key bit size to bytes.
    local key = blob(params.getKeySize() / 8); 
    Crypto.generateRandomBytes(key);

    return DecryptKey(Blob(key, false));
  }

  /**
   * Derive a new encrypt key from the given decrypt key value.
   * @param {Blob} keyBits The key value of the decrypt key.
   * @return {EncryptKey} The new encrypt key.
   */
  static function deriveEncryptKey(keyBits) { return EncryptKey(keyBits); }

  /**
   * Decrypt the encryptedData using the keyBits according the encrypt params.
   * @param {Blob} keyBits The key value.
   * @param {Blob} encryptedData The data to decrypt.
   * @param {EncryptParams} params This decrypts according to
   * params.getAlgorithmType() and other params as needed such as
   * params.getInitialVector().
   * @return {Blob} The decrypted data.
   */
  static function decrypt(keyBits, encryptedData, params)
  {
    local paddedData;
    if (params.getAlgorithmType() == EncryptAlgorithmType.AesEcb) {
      local cipher = AES(keyBits.buf().toBlob());
      // For the aes-squirrel package, we have to process each ECB block.
      local input = encryptedData.buf().toBlob();
      paddedData = blob(input.len());

      for (local i = 0; i < paddedData.len(); i += 16) {
        // TODO: Do we really have to copy once with readblob and again with writeblob?
        input.seek(i);
        paddedData.writeblob(cipher.decrypt(input.readblob(16)));
      }
    }
    else if (params.getAlgorithmType() == EncryptAlgorithmType.AesCbc) {
      local cipher = AES_CBC
        (keyBits.buf().toBlob(), params.getInitialVector().buf().toBlob());
      paddedData = cipher.decrypt(encryptedData.buf().toBlob());
    }
    else
      throw "Unsupported encryption mode";

    // For the aes-squirrel package, we have to remove the padding.
    local padLength = paddedData[paddedData.len() - 1];
    return Blob
      (Buffer.from(paddedData).slice(0, paddedData.len() - padLength), false);
  }

  /**
   * Encrypt the plainData using the keyBits according the encrypt params.
   * @param {Blob} keyBits The key value.
   * @param {Blob} plainData The data to encrypt.
   * @param {EncryptParams} params This encrypts according to
   * params.getAlgorithmType() and other params as needed such as
   * params.getInitialVector().
   * @return {Blob} The encrypted data.
   */
  static function encrypt(keyBits, plainData, params)
  {
    // For the aes-squirrel package, we have to do the padding.
    local padLength = 16 - (plainData.size() % 16);
    local paddedData = blob(plainData.size() + padLength);
    plainData.buf().copy(paddedData);
    for (local i = 0; i < padLength; ++i)
      paddedData[plainData.size() + i] = padLength;

    local encrypted;
    if (params.getAlgorithmType() == EncryptAlgorithmType.AesEcb) {
      local cipher = AES(keyBits.buf().toBlob());
      // For the aes-squirrel package, we have to process each ECB block.
      encrypted = blob(paddedData.len());

      for (local i = 0; i < paddedData.len(); i += 16) {
        // TODO: Do we really have to copy once with readblob and again with writeblob?
        paddedData.seek(i);
        encrypted.writeblob(cipher.encrypt(paddedData.readblob(16)));
      }
    }
    else if (params.getAlgorithmType() == EncryptAlgorithmType.AesCbc) {
      if (params.getInitialVector().size() != AesAlgorithm.BLOCK_SIZE)
        throw "Incorrect initial vector size";

      local cipher = AES_CBC
        (keyBits.buf().toBlob(), params.getInitialVector().buf().toBlob());
      encrypted = cipher.encrypt(paddedData);
    }
    else
      throw "Unsupported encryption mode";

    return Blob(Buffer.from(encrypted), false);
  }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * Encryptor has static constants and utility methods for encryption, such as
 * encryptData.
 */
class Encryptor {
  NAME_COMPONENT_FOR = NameComponent("FOR");
  NAME_COMPONENT_READ = NameComponent("READ");
  NAME_COMPONENT_SAMPLE = NameComponent("SAMPLE");
  NAME_COMPONENT_ACCESS = NameComponent("ACCESS");
  NAME_COMPONENT_E_KEY = NameComponent("E-KEY");
  NAME_COMPONENT_D_KEY = NameComponent("D-KEY");
  NAME_COMPONENT_C_KEY = NameComponent("C-KEY");

  /**
   * Prepare an encrypted data packet by encrypting the payload using the key
   * according to the params. In addition, this prepares the encoded
   * EncryptedContent with the encryption result using keyName and params. The
   * encoding is set as the content of the data packet. If params defines an
   * asymmetric encryption algorithm and the payload is larger than the maximum
   * plaintext size, this encrypts the payload with a symmetric key that is
   * asymmetrically encrypted and provided as a nonce in the content of the data
   * packet. The packet's /<dataName>/ is updated to be <dataName>/FOR/<keyName>.
   * @param {Data} data The data packet which is updated.
   * @param {Blob} payload The payload to encrypt.
   * @param {Name} keyName The key name for the EncryptedContent.
   * @param {Blob} key The encryption key value.
   * @param {EncryptParams} params The parameters for encryption.
   */
  static function encryptData(data, payload, keyName, key, params)
  {
    data.getName().append(Encryptor.NAME_COMPONENT_FOR).append(keyName);

    local algorithmType = params.getAlgorithmType();

    if (algorithmType == EncryptAlgorithmType.AesCbc ||
        algorithmType == EncryptAlgorithmType.AesEcb) {
      local content = Encryptor.encryptSymmetric_(payload, key, keyName, params);
      data.setContent(content.wireEncode(TlvWireFormat.get()));
    }
    else if (algorithmType == EncryptAlgorithmType.RsaPkcs ||
             algorithmType == EncryptAlgorithmType.RsaOaep) {
      // TODO: Support payload larger than the maximum plaintext size.
      local content = Encryptor.encryptAsymmetric_(payload, key, keyName, params);
      data.setContent(content.wireEncode(TlvWireFormat.get()));
    }
    else
      throw "Unsupported encryption method";
  }

  /**
   * Encrypt the payload using the symmetric key according to params, and return
   * an EncryptedContent.
   * @param {Blob} payload The data to encrypt.
   * @param {Blob} key The key value.
   * @param {Name} keyName The key name for the EncryptedContent key locator.
   * @param {EncryptParams} params The parameters for encryption.
   * @return {EncryptedContent} A new EncryptedContent.
   */
  static function encryptSymmetric_(payload, key, keyName, params)
  {
    local algorithmType = params.getAlgorithmType();
    local initialVector = params.getInitialVector();
    local keyLocator = KeyLocator();
    keyLocator.setType(KeyLocatorType.KEYNAME);
    keyLocator.setKeyName(keyName);

    if (algorithmType == EncryptAlgorithmType.AesCbc ||
        algorithmType == EncryptAlgorithmType.AesEcb) {
      if (algorithmType == EncryptAlgorithmType.AesCbc) {
        if (initialVector.size() != AesAlgorithm.BLOCK_SIZE)
          throw "Incorrect initial vector size";
      }

      local encryptedPayload = AesAlgorithm.encrypt(key, payload, params);

      local result = EncryptedContent();
      result.setAlgorithmType(algorithmType);
      result.setKeyLocator(keyLocator);
      result.setPayload(encryptedPayload);
      result.setInitialVector(initialVector);
      return result;
    }
    else
      throw "Unsupported encryption method";
  }

  /**
   * Encrypt the payload using the asymmetric key according to params, and
   * return an EncryptedContent.
   * @param {Blob} payload The data to encrypt. The size should be within range
   * of the key.
   * @param {Blob} key The key value.
   * @param {Name} keyName The key name for the EncryptedContent key locator.
   * @param {EncryptParams} params The parameters for encryption.
   * @return {EncryptedContent} A new EncryptedContent.
   */
  static function encryptAsymmetric_(payload, key, keyName, params)
  {
    local algorithmType = params.getAlgorithmType();
    local keyLocator = KeyLocator();
    keyLocator.setType(KeyLocatorType.KEYNAME);
    keyLocator.setKeyName(keyName);

    if (algorithmType == EncryptAlgorithmType.RsaPkcs ||
        algorithmType == EncryptAlgorithmType.RsaOaep) {
      local encryptedPayload = RsaAlgorithm.encrypt(key, payload, params);

      local result = EncryptedContent();
      result.setAlgorithmType(algorithmType);
      result.setKeyLocator(keyLocator);
      result.setPayload(encryptedPayload);
      return result;
    }
    else
      throw "Unsupported encryption method";
  }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

// This requires contrib/vukicevic/crunch/crunch.nut .

/**
 * The RsaAlgorithm class provides static methods to manipulate keys, encrypt
 * and decrypt using RSA.
 * @note This class is an experimental feature. The API may change.
 */
class RsaAlgorithm {
  /**
   * Generate a new random decrypt key for RSA based on the given params.
   * @param {RsaKeyParams} params The key params with the key size (in bits).
   * @return {DecryptKey} The new decrypt key (containing a PKCS8-encoded
   * private key).
   */
  static function generateKey(params)
  {
    // TODO: Implement
    throw "not implemented"
  }

  /**
   * Derive a new encrypt key from the given decrypt key value.
   * @param {Blob} keyBits The key value of the decrypt key (PKCS8-encoded
   * private key).
   * @return {EncryptKey} The new encrypt key.
   */
  static function deriveEncryptKey(keyBits)
  {
    // TODO: Implement
    throw "not implemented"
  }

  /**
   * Decrypt the encryptedData using the keyBits according the encrypt params.
   * @param {Blob} keyBits The key value (PKCS8-encoded private key).
   * @param {Blob} encryptedData The data to decrypt.
   * @param {EncryptParams} params This decrypts according to
   * params.getAlgorithmType().
   * @return {Blob} The decrypted data.
   */
  static function decrypt(keyBits, encryptedData, params)
  {
    // keyBits is PKCS #8 but we need the inner RSAPrivateKey.
    local rsaPrivateKeyDer = RsaAlgorithm.getRsaPrivateKeyDer(keyBits);

    // Decode the PKCS #1 RSAPrivateKey.
    local parsedNode = DerNode.parse(rsaPrivateKeyDer.buf(), 0);
    local children = parsedNode.getChildren();
    local n = children[1].toUnsignedArray();
    local e = children[2].toUnsignedArray();
    local d = children[3].toUnsignedArray();
    local p = children[4].toUnsignedArray();
    local q = children[5].toUnsignedArray();
    local dp1 = children[6].toUnsignedArray();
    local dq1 = children[7].toUnsignedArray();

    local crunch = Crypto.getCrunch();
    // Apparently, we can't use the private key's coefficient which is inv(q, p);
    local u = crunch.inv(p, q);
    local encryptedArray = array(encryptedData.buf().len());
    encryptedData.buf().copy(encryptedArray);
    local padded = crunch.gar(encryptedArray, p, q, d, u, dp1, dq1);

    // We have to remove the padding.
    // Note that Crunch strips the leading zero.
    if (padded[0] != 0x02)
      return "Invalid decrypted value";
    local iEndZero = padded.find(0x00);
    if (iEndZero == null)
      return "Invalid decrypted value";
    local iFrom = iEndZero + 1;
    local plainData = blob(padded.len() - iFrom);
    local iTo = 0;
    while (iFrom < padded.len())
      plainData[iTo++] = padded[iFrom++];

    return Blob(Buffer.from(plainData), false);
  }

  /**
   * Encrypt the plainData using the keyBits according the encrypt params.
   * @param {Blob} keyBits The key value (DER-encoded public key).
   * @param {Blob} plainData The data to encrypt.
   * @param {EncryptParams} params This encrypts according to
   * params.getAlgorithmType().
   * @return {Blob} The encrypted data.
   */
  static function encrypt(keyBits, plainData, params)
  {
    // keyBits is SubjectPublicKeyInfo but we need the inner RSAPublicKey.
    local rsaPublicKeyDer = RsaAlgorithm.getRsaPublicKeyDer(keyBits);

    // Decode the PKCS #1 RSAPublicKey.
    // TODO: Decode keyBits.
    local parsedNode = DerNode.parse(rsaPublicKeyDer.buf(), 0);
    local children = parsedNode.getChildren();
    local n = children[0].toUnsignedArray();
    local e = children[1].toUnsignedArray();

    // We have to do the padding.
    local padded = array(n.len());
    if (params.getAlgorithmType() == EncryptAlgorithmType.RsaPkcs) {
      padded[0] = 0x00;
      padded[1] = 0x02;

      // Fill with random non-zero bytes up to the end zero.
      local iEndZero = n.len() - 1 - plainData.size();
      if (iEndZero < 2)
        throw "Plain data size is too large";
      for (local i = 2; i < iEndZero; ++i) {
        local x = 0;
        while (x == 0)
          x = ((1.0 * math.rand() / RAND_MAX) * 256).tointeger();
        padded[i] = x;
      }

      padded[iEndZero] = 0x00;
      plainData.buf().copy(padded, iEndZero + 1);
    }
    else
      throw "Unsupported padding scheme";

    return Blob(Crypto.getCrunch().exp(padded, e, n));
  }

  /**
   * Decode the SubjectPublicKeyInfo, check that the algorithm is RSA, and
   * return the inner RSAPublicKey DER.
   * @param {Blob} The DER-encoded SubjectPublicKeyInfo.
   * @param {Blob} The DER-encoded RSAPublicKey.
   */
  static function getRsaPublicKeyDer(subjectPublicKeyInfo)
  {
    local parsedNode = DerNode.parse(subjectPublicKeyInfo.buf(), 0);
    local children = parsedNode.getChildren();
    local algorithmIdChildren = DerNode.getSequence(children, 0).getChildren();
/*  TODO: Finish implementing DerNode_DerOid
    local oidString = algorithmIdChildren[0].toVal();

    if (oidString != PrivateKeyStorage.RSA_ENCRYPTION_OID)
      throw "The PKCS #8 private key is not RSA_ENCRYPTION";
*/

    local payload = children[1].getPayload();
    // Remove the leading zero.
    return Blob(payload.buf().slice(1), false);
  }

  /**
   * Decode the PKCS #8 private key, check that the algorithm is RSA, and return
   * the inner RSAPrivateKey DER.
   * @param {Blob} The DER-encoded PKCS #8 private key.
   * @param {Blob} The DER-encoded RSAPrivateKey.
   */
  static function getRsaPrivateKeyDer(pkcs8PrivateKeyDer)
  {
    local parsedNode = DerNode.parse(pkcs8PrivateKeyDer.buf(), 0);
    local children = parsedNode.getChildren();
    local algorithmIdChildren = DerNode.getSequence(children, 1).getChildren();
/*  TODO: Finish implementing DerNode_DerOid
    local oidString = algorithmIdChildren[0].toVal();

    if (oidString != PrivateKeyStorage.RSA_ENCRYPTION_OID)
      throw "The PKCS #8 private key is not RSA_ENCRYPTION";
*/

    return children[2].getPayload();
  }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * A Consumer manages fetched group keys used to decrypt a data packet in the
 * group-based encryption protocol.
 * @note This class is an experimental feature. The API may change.
 */
class Consumer {
  // The map key is the C-KEY name URI string. The value is the encoded key Blob.
  // (Use a string because we can't use the Name object as the key in Squirrel.)
  cKeyMap_ = null;

  constructor()
  {
    cKeyMap_ = {};
  }

  /**
   * Decrypt encryptedContent using keyBits.
   * @param {Blob|EncryptedContent} encryptedContent The EncryptedContent to
   * decrypt, or a Blob which is first decoded as an EncryptedContent.
   * @param {Blob} keyBits The key value.
   * @param {function} onPlainText When encryptedBlob is decrypted, this calls
   * onPlainText(decryptedBlob) with the decrypted blob.
   * @param {function} onError This calls onError(errorCode, message) for an
   * error.
   */
  static function decrypt_(encryptedContent, keyBits, onPlainText, onError)
  {
    if (encryptedContent instanceof Blob) {
      // Decode as EncryptedContent.
      local encryptedBlob = encryptedContent;
      encryptedContent = EncryptedContent();
      encryptedContent.wireDecode(encryptedBlob);
    }

    local payload = encryptedContent.getPayload();

    if (encryptedContent.getAlgorithmType() == EncryptAlgorithmType.AesCbc) {
      // Prepare the parameters.
      local decryptParams = EncryptParams(EncryptAlgorithmType.AesCbc);
      decryptParams.setInitialVector(encryptedContent.getInitialVector());

      // Decrypt the content.
      local content = AesAlgorithm.decrypt(keyBits, payload, decryptParams);
      try {
        onPlainText(content);
      } catch (ex) {
        consoleLog("<DBUG>Error in onPlainText: " + ex + "</DBUG>");
      }
    }
    // TODO: Support RsaOaep.
    else {
      try {
        onError(EncryptError.ErrorCode.UnsupportedEncryptionScheme,
                "" + encryptedContent.getAlgorithmType());
      } catch (ex) {
        consoleLog("<DBUG>Error in onError: " + ex + "</DBUG>");
      }
    }
  }

  /**
   * Decrypt the data packet.
   * @param {Data} data The data packet. This does not verify the packet.
   * @param {function} onPlainText When the data packet is decrypted, this calls
   * onPlainText(decryptedBlob) with the decrypted Blob.
   * @param {function} onError This calls onError(errorCode, message) for an
   * error, where errorCode is an error code from EncryptError.ErrorCode.
   */
  function decryptContent_(data, onPlainText, onError)
  {
    // Get the encrypted content.
    local dataEncryptedContent = EncryptedContent();
    try {
      dataEncryptedContent.wireDecode(data.getContent());
    } catch (ex) {
      try {
        onError(EncryptError.ErrorCode.InvalidEncryptedFormat,
                "Error decoding EncryptedContent: " + ex);
      } catch (ex) {
        consoleLog("<DBUG>Error in onError: " + ex + "</DBUG>");
      }
      return;
    }
    local cKeyName = dataEncryptedContent.getKeyLocator().getKeyName();

    // Check if the content key is already in the store.
    if (cKeyName.toUri() in cKeyMap_)
      Consumer.decrypt_
        (dataEncryptedContent, cKeyMap_[cKeyName.toUri()], onPlainText, onError);
    else {
      Consumer.Error.callOnError
        (onError, "Can't find the C-KEY named cKeyName.toUri()", "");
/* TODO: Implment retrieving the C-KEY.
      // Retrieve the C-KEY Data from the network.
      var interestName = new Name(cKeyName);
      interestName.append(Encryptor.NAME_COMPONENT_FOR).append(this.groupName_);
      var interest = new Interest(interestName);

      // Prepare the callback functions.
      var thisConsumer = this;
      var onData = function(cKeyInterest, cKeyData) {
        // The Interest has no selectors, so assume the library correctly
        // matched with the Data name before calling onData.

        try {
          thisConsumer.keyChain_.verifyData(cKeyData, function(validCKeyData) {
            thisConsumer.decryptCKey_(validCKeyData, function(cKeyBits) {
              thisConsumer.cKeyMap_[cKeyName.toUri()] = cKeyBits;
              Consumer.decrypt_
                (dataEncryptedContent, cKeyBits, onPlainText, onError);
            }, onError);
          }, function(d) {
            onError(EncryptError.ErrorCode.Validation, "verifyData failed");
          });
        } catch (ex) {
          Consumer.Error.callOnError(onError, ex, "verifyData error: ");
        }
      };

      var onTimeout = function(dKeyInterest) {
        // We should re-try at least once.
        try {
          thisConsumer.face_.expressInterest
            (interest, onData, function(contentInterest) {
            onError(EncryptError.ErrorCode.Timeout, interest.getName().toUri());
           });
        } catch (ex) {
          Consumer.Error.callOnError(onError, ex, "expressInterest error: ");
        }
      };

      // Express the Interest.
      try {
        thisConsumer.face_.expressInterest(interest, onData, onTimeout);
      } catch (ex) {
        Consumer.Error.callOnError(onError, ex, "expressInterest error: ");
      }
*/
    }
  }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * A DecryptKey supplies the key for decrypt.
 * @note This class is an experimental feature. The API may change.
 */
class DecryptKey {
  keyBits_ = null;

  /**
   * Create a DecryptKey with the given key value.
   * @param {Blob|DecryptKey} value If value is another DecryptKey then copy it.
   * Otherwise, value is the key value.
   */
  constructor(value)
  {
    if (value instanceof DecryptKey)
      // The copy constructor.
      keyBits_ = value.keyBits_;
    else {
      local keyBits = value;
      keyBits_ = keyBits instanceof Blob ? keyBits : Blob(keyBits, true);
    }
  }

  /**
   * Get the key value.
   * @return {Blob} The key value.
   */
  function getKeyBits() { return keyBits_; }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * An EncryptKey supplies the key for encrypt.
 * @note This class is an experimental feature. The API may change.
 */
class EncryptKey {
  keyBits_ = null;

  /**
   * Create an EncryptKey with the given key value.
   * @param {Blob|EncryptKey} value If value is another EncryptKey then copy it.
   * Otherwise, value is the key value.
   */
  constructor(value)
  {
    if (value instanceof EncryptKey)
      // The copy constructor.
      keyBits_ = value.keyBits_;
    else {
      local keyBits = value;
      keyBits_ = keyBits instanceof Blob ? keyBits : Blob(keyBits, true);
    }
  }

  /**
   * Get the key value.
   * @return {Blob} The key value.
   */
  function getKeyBits() { return keyBits_; }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * EncryptError holds the ErrorCode values for errors from the encrypt library.
 */
class EncryptError {
  ErrorCode = {
    Timeout =                     1,
    Validation =                  2,
    UnsupportedEncryptionScheme = 32,
    InvalidEncryptedFormat =      33,
    NoDecryptKey =                34,
    EncryptionFailure =           35,
    General =                     100
  }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * An EncryptedContent holds an encryption type, a payload and other fields
 * representing encrypted content.
 */
class EncryptedContent {
  algorithmType_ = null;
  keyLocator_ = null;
  initialVector_ = null;
  payload_ = null;

  /**
   * Create a new EncryptedContent.
   * @param {EncryptedContent} value (optional) If value is another
   * EncryptedContent object, copy its values. Otherwise, create an
   * EncryptedContent with unspecified values.
   */
  constructor(value = null)
  {
    if (value instanceof EncryptedContent) {
      // Make a deep copy.
      algorithmType_ = value.algorithmType_;
      keyLocator_ = KeyLocator(value.keyLocator_);
      initialVector_ = value.initialVector_;
      payload_ = value.payload_;
    }
    else {
      algorithmType_ = null;
      keyLocator_ = KeyLocator();
      initialVector_ = Blob();
      payload_ = Blob();
    }
  }

  /**
   * Get the algorithm type from EncryptAlgorithmType.
   * @return {integer} The algorithm type from the EncryptAlgorithmType enum, or
   * null if not specified.
   */
  function getAlgorithmType() { return algorithmType_; }

  /**
   * Get the key locator.
   * @return {KeyLocator} The key locator. If not specified, getType() is null.
   */
  function getKeyLocator() { return keyLocator_; }

  /**
   * Get the initial vector.
   * @return {Blob} The initial vector. If not specified, isNull() is true.
   */
  function getInitialVector() { return initialVector_; }

  /**
   * Get the payload.
   * @return {Blob} The payload. If not specified, isNull() is true.
   */
  function getPayload() { return payload_; }

  /**
   * Set the algorithm type.
   * @param {integer} algorithmType The algorithm type from the
   * EncryptAlgorithmType enum. If not specified, set to null.
   * @return {EncryptedContent} This EncryptedContent so that you can chain
   * calls to update values.
   */
  function setAlgorithmType(algorithmType)
  {
    algorithmType_ = algorithmType;
    return this;
  }

  /**
   * Set the key locator.
   * @param {KeyLocator} keyLocator The key locator. This makes a copy of the
   * object. If not specified, set to the default KeyLocator().
   * @return {EncryptedContent} This EncryptedContent so that you can chain
   * calls to update values.
   */
  function setKeyLocator(keyLocator)
  {
    keyLocator_ = keyLocator instanceof KeyLocator ?
      KeyLocator(keyLocator) : KeyLocator();
    return this;
  }

  /**
   * Set the initial vector.
   * @param {Blob} initialVector The initial vector. If not specified, set to
   * the default Blob() where isNull() is true.
   * @return {EncryptedContent} This EncryptedContent so that you can chain
   * calls to update values.
   */
  function setInitialVector(initialVector)
  {
    initialVector_ = initialVector instanceof Blob ?
      initialVector : Blob(initialVector, true);
    return this;
  }

  /**
   * Set the encrypted payload.
   * @param {Blob} payload The payload. If not specified, set to the default
   * Blob() where isNull() is true.
   * @return {EncryptedContent} This EncryptedContent so that you can chain
   * calls to update values.
   */
  function setPayload(payload)
  {
    payload_ = payload instanceof Blob ? payload : Blob(payload, true);
    return this;
  }

  /**
   * Encode this EncryptedContent for a particular wire format.
   * @param {WireFormat} wireFormat (optional) A WireFormat object used to
   * encode this object. If null or omitted, use WireFormat.getDefaultWireFormat().
   * @return {Blob} The encoded buffer in a Blob object.
   */
  function wireEncode(wireFormat = null)
  {
    if (wireFormat == null)
        // Don't use a default argument since getDefaultWireFormat can change.
        wireFormat = WireFormat.getDefaultWireFormat();

    return wireFormat.encodeEncryptedContent(this);
  }

  /**
   * Decode the input using a particular wire format and update this
   * EncryptedContent.
   * @param {Blob|Buffer} input The buffer with the bytes to decode.
   * @param {WireFormat} wireFormat (optional) A WireFormat object used to
   * decode this object. If null or omitted, use WireFormat.getDefaultWireFormat().
   */
  function wireDecode(input, wireFormat = null)
  {
    if (wireFormat == null)
        // Don't use a default argument since getDefaultWireFormat can change.
        wireFormat = WireFormat.getDefaultWireFormat();

    if (input instanceof Blob)
      wireFormat.decodeEncryptedContent(this, input.buf(), false);
    else
      wireFormat.decodeEncryptedContent(this, input, true);
  }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * PrivateKeyStorage is an abstract class which declares methods for working
 * with a private key storage. You should use a subclass.
 */
class PrivateKeyStorage {
  RSA_ENCRYPTION_OID = "1.2.840.113549.1.1.1";
  EC_ENCRYPTION_OID = "1.2.840.10045.2.1";
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * This module defines constants used by the security library.
 */

/**
 * The KeyType enum is used by the Sqlite key storage, so don't change them.
 * Make these the same as ndn-cxx in case the storage file is shared.
 */
enum KeyType {
  RSA = 0,
  ECDSA = 1,
  AES = 128
}

enum KeyClass {
  PUBLIC = 1,
  PRIVATE = 2,
  SYMMETRIC = 3
}

enum DigestAlgorithm {
  SHA256 = 1
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * KeyParams is a base class for key parameters. Its subclasses are used to
 * store parameters for key generation. You should create one of the subclasses,
 * for example RsaKeyParams.
 */
class KeyParams {
  keyType_ = 0;

  constructor(keyType)
  {
    keyType_ = keyType;
  }

  function getKeyType() { return keyType_; }
}

class RsaKeyParams extends KeyParams {
  size_ = 0;

  constructor(size = null)
  {
    base.constructor(RsaKeyParams.getType());

    if (size == null)
      size = RsaKeyParams.getDefaultSize();
    size_ = size;
  }

  function getKeySize() { return size_; }

  static function getDefaultSize() { return 2048; }

  static function getType() { return KeyType.RSA; }
}

class AesKeyParams extends KeyParams {
  size_ = 0;

  constructor(size = null)
  {
    base.constructor(AesKeyParams.getType());

    if (size == null)
      size = AesKeyParams.getDefaultSize();
    size_ = size;
  }

  function getKeySize() { return size_; }

  static function getDefaultSize() { return 64; }

  static function getType() { return KeyType.AES; }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * A KeyChain provides a set of interfaces to the security library such as
 * identity management, policy configuration and packet signing and verification.
 * Note: This class is an experimental feature. See the API docs for more detail at
 * http://named-data.net/doc/ndn-ccl-api/key-chain.html .
 */
class KeyChain {
  /**
   * Wire encode the target, compute an HmacWithSha256 and update the signature
   * value.
   * Note: This method is an experimental feature. The API may change.
   * @param {Data} target If this is a Data object, update its signature and
   * wire encoding.
   * @param {Blob} key The key for the HmacWithSha256.
   * @param {WireFormat} wireFormat (optional) A WireFormat object used to
   * encode the target. If omitted, use WireFormat getDefaultWireFormat().
   */
  static function signWithHmacWithSha256(target, key, wireFormat = null)
  {
    if (target instanceof Data) {
      local data = target;
      // Encode once to get the signed portion.
      local encoding = data.wireEncode(wireFormat);
      local signatureBytes = NdnCommon.computeHmacWithSha256
        (key.buf(), encoding.signedBuf());
      data.getSignature().setSignature(Blob(signatureBytes, false));
    }
    else
      throw "Unrecognized target type";
  }

  /**
   * Compute a new HmacWithSha256 for the target and verify it against the
   * signature value.
   * Note: This method is an experimental feature. The API may change.
   * @param {Data} target The Data object to verify.
   * @param {Blob} key The key for the HmacWithSha256.
   * @param {WireFormat} wireFormat (optional) A WireFormat object used to
   * encode the target. If omitted, use WireFormat getDefaultWireFormat().
   * @return {bool} True if the signature verifies, otherwise false.
   */
  static function verifyDataWithHmacWithSha256(data, key, wireFormat = null)
  {
    // wireEncode returns the cached encoding if available.
    local encoding = data.wireEncode(wireFormat);
    local newSignatureBytes = Blob(NdnCommon.computeHmacWithSha256
      (key.buf(), encoding.signedBuf()), false);

    // Use the flexible Blob.equals operator.
    return newSignatureBytes.equals(data.getSignature().getSignature());
  };
}
/**
 * Copyright (C) 2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * A DelayedCallTable which is an internal class used by the Face implementation
 * of callLater to store callbacks and call them when they time out.
 */
class DelayedCallTable {
  table_ = null;          // Array of DelayedCallTableEntry

  constructor()
  {
    table_ = [];
  }

  /*
   * Call callback() after the given delay. This adds to the delayed call table
   * which is used by callTimedOut().
   * @param {float} delayMilliseconds: The delay in milliseconds.
   * @param {function} callback This calls callback() after the delay.
   */
  function callLater(delayMilliseconds, callback)
  {
    local entry = DelayedCallTableEntry(delayMilliseconds, callback);
    // Insert into table_, sorted on getCallTimeSeconds().
    // Search from the back since we expect it to go there.
    local i = table_.len() - 1;
    while (i >= 0) {
      if (table_[i].getCallTimeSeconds() <= entry.getCallTimeSeconds())
        break;
      --i;
    }

    // Element i is the greatest less than or equal to entry.getCallTimeSeconds(), so
    // insert after it.
    table_.insert(i + 1, entry);
  }

  /**
   * Call and remove timed-out callback entries. Since callLater does a sorted
   * insert into the delayed call table, the check for timed-out entries is
   * quick and does not require searching the entire table.
   */
  function callTimedOut()
  {
    local nowSeconds = NdnCommon.getNowSeconds();
    // table_ is sorted on _callTime, so we only need to process the timed-out
    // entries at the front, then quit.
    while (table_.len() > 0 && table_[0].getCallTimeSeconds() <= nowSeconds) {
      local entry = table_[0];
      table_.remove(0);
      entry.callCallback();
    }
  }
}

/**
 * DelayedCallTableEntry holds the callback and other fields for an entry in the
 * delayed call table.
 */
class DelayedCallTableEntry {
  callback_ = null;
  callTimeSeconds_ = 0.0;

  /*
   * Create a new DelayedCallTableEntry and set the call time based on the
   * current time and the delayMilliseconds.
   * @param {float} delayMilliseconds: The delay in milliseconds.
   * @param {function} callback This calls callback() after the delay.
   */
  constructor(delayMilliseconds, callback)
  {
    callback_ = callback;
    local nowSeconds = NdnCommon.getNowSeconds();
    callTimeSeconds_ = nowSeconds + (delayMilliseconds / 1000.0).tointeger();
  }

  /**
   * Get the time at which the callback should be called.
   * @return {float} The call time in seconds, based on NdnCommon.getNowSeconds().
   */
  function getCallTimeSeconds() { return callTimeSeconds_; }

  /**
   * Call the callback given to the constructor. This does not catch exceptions.
   */
  function callCallback() { callback_(); }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * An InterestFilterTable is an internal class to hold a list of entries with
 * an interest Filter and its OnInterestCallback.
 */
class InterestFilterTable {
  table_ = null; // Array of InterestFilterTableEntry

  constructor()
  {
    table_ = [];
  }

  /**
   * Add a new entry to the table.
   * @param {integer} interestFilterId The ID from Node.getNextEntryId().
   * @param {InterestFilter} filter The InterestFilter for this entry.
   * @param {function} onInterest The callback to call.
   * @param {Face} face The face on which was called registerPrefix or
   * setInterestFilter which is passed to the onInterest callback.
   */
  function setInterestFilter(interestFilterId, filter, onInterest, face)
  {
    table_.append(InterestFilterTableEntry
      (interestFilterId, filter, onInterest, face));
  }

  /**
   * Find all entries from the interest filter table where the interest conforms
   * to the entry's filter, and add to the matchedFilters list.
   * @param {Interest} interest The interest which may match the filter in
   * multiple entries.
   * @param {Array<InterestFilterTableEntry>} matchedFilters Add each matching
   * InterestFilterTableEntry from the interest filter table.  The caller
   * should pass in an empty array.
   */
  function getMatchedFilters(interest, matchedFilters)
  {
    foreach (entry in table_) {
      if (entry.getFilter().doesMatch(interest.getName()))
        matchedFilters.append(entry);
    }
  }

  // TODO: unsetInterestFilter
}

/**
 * InterestFilterTable.Entry holds an interestFilterId, an InterestFilter and
 * the OnInterestCallback with its related Face.
 */
class InterestFilterTableEntry {
  interestFilterId_ = 0;
  filter_ = null;
  onInterest_ = null;
  face_ = null;

  /**
   * Create a new InterestFilterTableEntry with the given values.
   * @param {integer} interestFilterId The ID from getNextEntryId().
   * @param {InterestFilter} filter The InterestFilter for this entry.
   * @param {function} onInterest The callback to call.
   * @param {Face} face The face on which was called registerPrefix or
   * setInterestFilter which is passed to the onInterest callback.
   */
  constructor(interestFilterId, filter, onInterest, face)
  {
    interestFilterId_ = interestFilterId;
    filter_ = filter;
    onInterest_ = onInterest;
    face_ = face;
  }

  /**
   * Get the interestFilterId given to the constructor.
   * @return {integer} The interestFilterId.
   */
  function getInterestFilterId () { return interestFilterId_; }

  /**
   * Get the InterestFilter given to the constructor.
   * @return {InterestFilter} The InterestFilter.
   */
  function getFilter() { return filter_; }

  /**
   * Get the onInterest callback given to the constructor.
   * @return {function} The onInterest callback.
   */
  function getOnInterest() { return onInterest_; }

  /**
   * Get the Face given to the constructor.
   * @return {Face} The Face.
   */
  function getFace() { return face_; }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * A PendingInterestTable is an internal class to hold a list of pending
 * interests with their callbacks.
 */
class PendingInterestTable {
  table_ = null;          // Array of PendingInterestTableEntry
  removeRequests_ = null; // Array of integer

  constructor()
  {
    table_ = [];
    removeRequests_ = [];
  }

  /**
   * Add a new entry to the pending interest table. However, if 
   * removePendingInterest was already called with the pendingInterestId, don't
   * add an entry and return null.
   * @param {integer} pendingInterestId
   * @param {Interest} interestCopy
   * @param {function} onData
   * @param {function} onTimeout
   * @param {function} onNetworkNack
   * @return {PendingInterestTableEntry} The new PendingInterestTableEntry, or
   * null if removePendingInterest was already called with the pendingInterestId.
   */
  function add(pendingInterestId, interestCopy, onData, onTimeout, onNetworkNack)
  {
    local removeRequestIndex = removeRequests_.find(pendingInterestId);
    if (removeRequestIndex != null) {
      // removePendingInterest was called with the pendingInterestId returned by
      //   expressInterest before we got here, so don't add a PIT entry.
      removeRequests_.remove(removeRequestIndex);
      return null;
    }

    local entry = PendingInterestTableEntry
      (pendingInterestId, interestCopy, onData, onTimeout, onNetworkNack);
    table_.append(entry);
    return entry;
  }

  /**
   * Find all entries from the pending interest table where data conforms to
   * the entry's interest selectors, remove the entries from the table, set each
   * entry's isRemoved flag, and add to the entries list.
   * @param {Data} data The incoming Data packet to find the interest for.
   * @param {Array<PendingInterestTableEntry>} entries Add matching
   * PendingInterestTableEntry from the pending interest table. The caller
   * should pass in an empty array.
   */
  function extractEntriesForExpressedInterest(data, entries)
  {
    // Go backwards through the list so we can erase entries.
    for (local i = table_.len() - 1; i >= 0; --i) {
      local pendingInterest = table_[i];

      if (pendingInterest.getInterest().matchesData(data)) {
        entries.append(pendingInterest);
        table_.remove(i);
        // We let the callback from callLater call _processInterestTimeout,
        // but for efficiency, mark this as removed so that it returns
        // right away.
        pendingInterest.setIsRemoved();
      }
    }
  }

  // TODO: extractEntriesForNackInterest
  // TODO: removePendingInterest

  /**
   * Remove the specific pendingInterest entry from the table and set its
   * isRemoved flag. However, if the pendingInterest isRemoved flag is already
   * true or the entry is not in the pending interest table then do nothing.
   * @param {PendingInterestTableEntry} pendingInterest The Entry from the
   * pending interest table.
   * @return {bool} True if the entry was removed, false if not.
   */
  function removeEntry(pendingInterest)
  {
    if (pendingInterest.getIsRemoved())
      // extractEntriesForExpressedInterest or removePendingInterest has removed
      // pendingInterest from the table, so we don't need to look for it. Do
      // nothing.
      return false;

    local index = table_.find(pendingInterest);
    if (index == null)
      // The pending interest has been removed. Do nothing.
      return false;

    pendingInterest.setIsRemoved();
    table_.remove(index);
    return true;
  }
}

/**
 * PendingInterestTableEntry holds the callbacks and other fields for an entry
 * in the pending interest table.
 */
class PendingInterestTableEntry {
  pendingInterestId_ = 0;
  interest_ = null;
  onData_ = null;
  onTimeout_ = null;
  onNetworkNack_ = null;
  isRemoved_ = false;

  /*
   * Create a new Entry with the given fields. Note: You should not call this
   * directly but call PendingInterestTable.add.
   */
  constructor(pendingInterestId, interest, onData, onTimeout, onNetworkNack)
  {
    pendingInterestId_ = pendingInterestId;
    interest_ = interest;
    onData_ = onData;
    onTimeout_ = onTimeout;
    onNetworkNack_ = onNetworkNack;
  }

  /**
   * Get the pendingInterestId given to the constructor.
   * @return {integer} The pendingInterestId.
   */
  function getPendingInterestId() { return this.pendingInterestId_; }

  /**
   * Get the interest given to the constructor (from Face.expressInterest).
   * @return {Interest} The interest. NOTE: You must not change the interest
   * object - if you need to change it then make a copy.
   */
  function getInterest() { return this.interest_; }

  /**
   * Get the OnData callback given to the constructor.
   * @return {function} The OnData callback.
   */
  function getOnData() { return this.onData_; }

  /**
   * Get the OnNetworkNack callback given to the constructor.
   * @return {function} The OnNetworkNack callback.
   */
  function getOnNetworkNack() { return this.onNetworkNack_; }

  /**
   * Call onTimeout_ (if defined).  This ignores exceptions from onTimeout_.
   */
  function callTimeout()
  {
    if (onTimeout_ != null) {
      try {
        onTimeout_(interest_);
      } catch (ex) {
        consoleLog("<DBUG>Error in onTimeout: " + ex + "</DBUG>");
      }
    }
  }

  /**
   * Set the isRemoved flag which is returned by getIsRemoved().
   */
  function setIsRemoved() { isRemoved_ = true; }

  /**
   * Check if setIsRemoved() was called.
   * @return {bool} True if setIsRemoved() was called.
   */
  function getIsRemoved() { return isRemoved_; }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * Transport is a base class for specific transport classes such as 
 * AgentDeviceTransport.
 */
class Transport {
}

/**
 * TransportConnectionInfo is a base class for connection information used by
 * subclasses of Transport.
 */
class TransportConnectionInfo {
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * An AsyncTransport extends Transport to communicate with a connection
 * object which supports a "write" method and a "setAsyncCallbacks" method which
 * registers a callback for onDataReceived which asynchronously supplies
 * incoming data. See the "connect" method for details.
 */
class AsyncTransport extends Transport {
  elementReader_ = null;
  connectionObject_ = null;

  /**
   * Connect to the connection object by calling
   * connectionInfo.getConnectionObject().setAsyncCallbacks(this) so that the
   * connection object asynchronously calls this.onDataReceived(data) on
   * receiving incoming data. (data is a Squirrel blob.) This Read an entire
   * packet element and calls elementListener.onReceivedElement(element). To 
   * send data, this calls connectionInfo.getConnectionObject().write(data)
   * where data is a Squirrel blob.
   * @param {AsyncTransportConnectionInfo} connectionInfo The ConnectionInfo with
   * the connection object. This assumes you have already configured the
   * connection object for communication as needed. (If not, you must configure
   * it when this calls setAsyncCallbacks.)
   * @param {instance} elementListener The elementListener with function
   * onReceivedElement which must remain valid during the life of this object.
   * @param {function} onOpenCallback Once connected, call onOpenCallback().
   * @param {function} onClosedCallback (optional) If the connection is closed 
   * by the remote host, call onClosedCallback(). If omitted or null, don't call
   * it.
   */
  function connect
    (connectionInfo, elementListener, onOpenCallback, onClosedCallback = null)
  {
    elementReader_ = ElementReader(elementListener);
    connectionObject_ = connectionInfo.getConnectionObject();

    // Register to receive data.
    connectionObject_.setAsyncCallbacks(this);

    if (onOpenCallback != null)
      onOpenCallback();
  }

  /**
   * Write the bytes to the UART.
   * @param {Buffer} buffer The bytes to send.
   */
  function send(buffer)
  {
    connectionObject_.write(buffer.toBlob());
  }

  /** This is called asynchronously when the connection object receives data.
   * Pass the data to the elementReader_.
   * @param {blob} data The Squirrel blob with the received data.
   */
  function onDataReceived(data)
  {
    elementReader_.onReceivedData(Buffer.from(data));
  }
}

/**
 * An AsyncTransportConnectionInfo extends TransportConnectionInfo to hold the
 * object which has the "setAsyncCallbacks" method. See the "connect" method for
 * details.
 */
class AsyncTransportConnectionInfo extends TransportConnectionInfo {
  connectionObject_ = null;

  /**
   * Create a new AsyncTransportConnectionInfo with the given connection object.
   * See AsyncTransport.connect method for details.
   * @param {instance} connectionObject The connection object which has the
   * "setAsyncCallbacks" method.
   */
  constructor(connectionObject)
  {
    connectionObject_ = connectionObject;
  }

  /**
   * Get the connection object given to the constructor.
   * @return {instance} The connection object.
   */
  function getConnectionObject() { return connectionObject_; }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * A SquirrelObjectTransport extends Transport to communicate with a connection
 * object which supports "on" and "send" methods, such as an Imp agent or device
 * object. This can send a blob as well as another type of Squirrel object.
 */
class SquirrelObjectTransport extends Transport {
  elementReader_ = null;
  onReceivedObject_ = null;
  connection_ = null;

  /**
   * Set the onReceivedObject callback, replacing any previous callback.
   * @param {function} onReceivedObject If the received object is not a blob
   * then just call onReceivedObject(obj). If this is null, then don't call it.
   */
  function setOnReceivedObject(onReceivedObject)
  {
    onReceivedObject_ = onReceivedObject;
  }

  /**
   * Connect to the connection object given by connectionInfo.getConnnection(),
   * communicating with connection.on and connection.send using the message name
   * "NDN". If a received object is a Squirrel blob, make a Buffer from it and
   * use it to read an entire packet element and call
   * elementListener.onReceivedElement(element). Otherwise just call
   * onReceivedObject(obj) using the callback given to the constructor.
   * @param {SquirrelObjectTransportConnectionInfo} connectionInfo The
   * ConnectionInfo with the connection object.
   * @param {instance} elementListener The elementListener with function
   * onReceivedElement which must remain valid during the life of this object.
   * @param {function} onOpenCallback Once connected, call onOpenCallback().
   * @param {function} onClosedCallback (optional) If the connection is closed 
   * by the remote host, call onClosedCallback(). If omitted or null, don't call
   * it.
   */
  function connect
    (connectionInfo, elementListener, onOpenCallback, onClosedCallback = null)
  {
    elementReader_ = ElementReader(elementListener);
    connection_ = connectionInfo.getConnnection();

    // Add a listener to wait for a message object.
    local thisTransport = this;
    connection_.on("NDN", function(obj) {
      if (typeof obj == "blob") {
        try {
          thisTransport.elementReader_.onReceivedData(Buffer.from(obj));
        } catch (ex) {
          consoleLog("<DBUG>Error in onReceivedData: " + ex + "</DBUG>");
        }
      }
      else {
        if (thisTransport.onReceivedObject_ != null) {
          try {
            thisTransport.onReceivedObject_(obj);
          } catch (ex) {
            consoleLog("<DBUG>Error in onReceivedObject: " + ex + "</DBUG>");
          }
        }
      }
    });

    if (onOpenCallback != null)
      onOpenCallback();
  }

  /**
   * Send the object over the connection created by connect, using the message
   * name "NDN".
   * @param {blob|table} obj The object to send. If it is a blob then it is
   * processed like an NDN packet.
   */
  function sendObject(obj) 
  {
    if (connection_ == null)
      throw "not connected";
    connection_.send("NDN", obj);
  }

  /**
   * Convert the buffer to a Squirrel blob and send it over the connection
   * created by connect.
   * @param {Buffer} buffer The bytes to send.
   */
  function send(buffer)
  {
    sendObject(buffer.toBlob());
  }
}

/**
 * An SquirrelObjectTransportConnectionInfo extends TransportConnectionInfo to
 * hold the connection object.
 */
class SquirrelObjectTransportConnectionInfo extends TransportConnectionInfo {
  connection_ = null;

  /**
   * Create a new SquirrelObjectTransportConnectionInfo with the connection
   * object.
   * @param {instance} connection The connection object which supports "on" and
   * "send" methods, such as an Imp agent or device object.
   */
  constructor(connection)
  {
    connection_ = connection;
  }

  /**
   * Get the connection object given to the constructor.
   * @return {instance} The connection object.
   */
  function getConnnection() { return connection_; }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * A MicroForwarderTransport extends Transport to communicate with a
 * MicroForwarder object. This also supports "on" and "send" methods so that
 * this can be used by SquirrelObjectTransport as the connection object (see
 * connect).
 */
class MicroForwarderTransport extends Transport {
  elementReader_ = null;
  onReceivedObject_ = null;
  onCallbacks_ = null; // array of function which takes a Squirrel object.

  /**
   * Create a MicroForwarderTransport.
   * @param {function} onReceivedObject (optional) If supplied and the received
   * object is not a blob then just call onReceivedObject(obj).
   */
  constructor(onReceivedObject = null) {
    onReceivedObject_ = onReceivedObject;
    onCallbacks_ = [];
  }

  /**
   * Connect to connectionInfo.getForwarder() by calling its addFace and using
   * this as the connection object. If a received object is a Squirrel blob,
   * make a Buffer from it and use it to read an entire packet element and call
   * elementListener.onReceivedElement(element). Otherwise just call
   * onReceivedObject(obj) using the callback given to the constructor.
   * @param {MicroForwarderTransportConnectionInfo} connectionInfo The
   * ConnectionInfo with the MicroForwarder object.
   * @param {instance} elementListener The elementListener with function
   * onReceivedElement which must remain valid during the life of this object.
   * @param {function} onOpenCallback Once connected, call onOpenCallback().
   * @param {function} onClosedCallback (optional) If the connection is closed 
   * by the remote host, call onClosedCallback(). If omitted or null, don't call
   * it.
   */
  function connect
    (connectionInfo, elementListener, onOpenCallback, onClosedCallback = null)
  {
    elementReader_ = ElementReader(elementListener);
    connectionInfo.getForwarder().addFace
      ("internal://app", SquirrelObjectTransport(),
       SquirrelObjectTransportConnectionInfo(this));

    if (onOpenCallback != null)
      onOpenCallback();
  }

  /**
   * Send the object to the MicroForwarder over the connection created by
   * connect (and to anyone else who called on("NDN", callback)).
   * @param {blob|table} obj The object to send. If it is a blob then it is
   * processed by the MicroForwarder like an NDN packet.
   */
  function sendObject(obj) 
  {
    if (onCallbacks_.len() == null)
      // There should have been at least one callback added during connect.
      throw "not connected";

    foreach (callback in onCallbacks_)
      callback(obj);
  }

  /**
   * This is overloaded with the following two forms:
   * send(buffer) - Convert the buffer to a Squirrel blob and send it to the
   * MicroForwarder over the connection created by connect (and to anyone else
   * who called on("NDN", callback)).
   * send(messageName, obj) - When the MicroForwarder calls send, if it is a
   * Squirrel blob then make a Buffer from it and use it to read an entire
   * packet element and call elementListener_.onReceivedElement(element),
   * otherwise just call onReceivedObject(obj) using the callback given to the
   * constructor.
   * @param {Buffer} buffer The bytes to send.
   * @param {string} messageName The name of the message if calling
   * send(messageName, obj). If messageName is not "NDN", do nothing.
   * @param {blob|table} obj The object if calling send(messageName, obj).
   */
  function send(arg1, obj = null)
  {
    if (arg1 instanceof Buffer)
      sendObject(arg1.toBlob());
    else {
      if (arg1 != "NDN")
        // The messageName is not "NDN". Ignore.
        return;

      if (typeof obj == "blob") {
        try {
          elementReader_.onReceivedData(Buffer.from(obj));
        } catch (ex) {
          consoleLog("<DBUG>Error in onReceivedData: " + ex + "</DBUG>");
        }
      }
      else {
        if (onReceivedObject_ != null) {
          try {
            onReceivedObject_(obj);
          } catch (ex) {
            consoleLog("<DBUG>Error in onReceivedObject: " + ex + "</DBUG>");
          }
        }
      }
    }
  }

  function on(messageName, callback)
  {
    if (messageName != "NDN")
      return;
    onCallbacks_.append(callback);
  }
}

/**
 * A MicroForwarderTransportConnectionInfo extends TransportConnectionInfo to
 * hold the MicroForwarder object to connect to.
 */
class MicroForwarderTransportConnectionInfo extends TransportConnectionInfo {
  forwarder_ = null;

  /**
   * Create a new MicroForwarderTransportConnectionInfo with the forwarder
   * object.
   * @param {MicroForwarder} forwarder (optional) The MicroForwarder to
   * communicate with. If omitted or null, use the static MicroForwarder.get().
   */
  constructor(forwarder = null)
  {
    forwarder_ = forwarder != null ? forwarder : MicroForwarder.get();
  }

  /**
   * Get the MicroForwarder object given to the constructor.
   * @return {MicroForwarder} The MicroForwarder object.
   */
  function getForwarder() { return forwarder_; }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * A UartTransport extends Transport to communicate with a connection
 * object which supports "write" and "readblob" methods, such as an Imp uart
 * object.
 */
class UartTransport extends Transport {
  elementReader_ = null;
  uart_ = null;
  readInterval_ = 0

  /**
   * Create a UartTransport in the unconnected state.
   * @param {float} (optional) The interval in seconds for polling the UART to
   * read. If omitted, use a default value.
   */
  constructor(readInterval = 0.5)
  {
    readInterval_ = readInterval;
  }

  /**
   * Connect to the connection object given by connectionInfo.getUart(),
   * communicating with getUart().write() and getUart().readblob(). Read an
   * entire packet element and call elementListener.onReceivedElement(element).
   * This starts a timer using imp.wakeup to repeatedly read the input according
   * to the readInterval given to the constructor.
   * @param {UartTransportConnectionInfo} connectionInfo The ConnectionInfo with 
   * the uart object. This assumes you have already called configure() as needed.
   * @param {instance} elementListener The elementListener with function
   * onReceivedElement which must remain valid during the life of this object.
   * @param {function} onOpenCallback Once connected, call onOpenCallback().
   * @param {function} onClosedCallback (optional) If the connection is closed 
   * by the remote host, call onClosedCallback(). If omitted or null, don't call
   * it.
   */
  function connect
    (connectionInfo, elementListener, onOpenCallback, onClosedCallback = null)
  {
    elementReader_ = ElementReader(elementListener);
    uart_ = connectionInfo.getUart();

    // This will start the read timer.
    read();

    if (onOpenCallback != null)
      onOpenCallback();
  }

  /**
   * Write the bytes to the UART.
   * @param {Buffer} buffer The bytes to send.
   */
  function send(buffer)
  {
    uart_.write(buffer.toBlob());
  }

  /**
   * Read bytes from the uart_ and pass to the elementReader_, then use
   * imp.wakeup to call this again after readInterval_ seconds.
   */
  function read()
  {
    // Loop until there is no more data in the receive buffer.
    while (true) {
      local input = uart_.readblob();
      if (input.len() <= 0)
        break;

      elementReader_.onReceivedData(Buffer.from(input));
    }

    // Restart the read timer.
    // TODO: How to close the connection?
    local thisTransport = this;
    imp.wakeup(readInterval_, function() { thisTransport.read(); });
  }
}

/**
 * An UartTransportConnectionInfo extends TransportConnectionInfo to hold the
 * uart object.
 */
class UartTransportConnectionInfo extends TransportConnectionInfo {
  uart_ = null;

  /**
   * Create a new UartTransportConnectionInfo with the uart object.
   * @param {instance} uart The uart object which supports "write" and
   * "readblob" methods, such as hardware.uart0.
   */
  constructor(uart)
  {
    uart_ = uart;
  }

  /**
   * Get the uart object given to the constructor.
   * @return {instance} The uart object.
   */
  function getUart() { return uart_; }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

enum FaceConnectStatus_ { UNCONNECTED, CONNECT_REQUESTED, CONNECT_COMPLETE }

/**
 * A Face provides the top-level interface to the library. It holds a connection
 * to a forwarder and supports interest / data exchange.
 */
class Face {
  transport_ = null;
  connectionInfo_ = null;
  pendingInterestTable_ = null;
  interestFilterTable_ = null;
  registeredPrefixTable_ = null;
  delayedCallTable_ = null;
  connectStatus_ = FaceConnectStatus_.UNCONNECTED;
  lastEntryId_ = 0;
  doingProcessEvents_ = false;
  timeoutPrefix_ = Name("/local/timeout");
  nonceTemplate_ = Blob(Buffer(4), false);

  /**
   * Create a new Face. The constructor has the forms Face() or
   * Face(transport, connectionInfo). If the default Face() constructor is
   * used, create a MicroForwarderTransport connection to the static instance
   * MicroForwarder.get(). Otherwise connect using the given transport and
   * connectionInfo.
   * @param {Transport} transport (optional) An object of a subclass of
   * Transport to use for communication. If supplied, you must also supply a
   * connectionInfo.
   * @param {TransportConnectionInfo} connectionInfo (optional) This must be a
   * ConnectionInfo from the same subclass of Transport as transport.
   */
  constructor(transport = null, connectionInfo = null)
  {
    if (transport == null) {
      transport_ = MicroForwarderTransport();
      connectionInfo_ = MicroForwarderTransportConnectionInfo();
    }
    else {
      transport_ = transport;
      connectionInfo_ = connectionInfo;
    }

    pendingInterestTable_ = PendingInterestTable();
    interestFilterTable_ = InterestFilterTable();
// TODO    registeredPrefixTable_ = RegisteredPrefixTable(interestFilterTable_);
    delayedCallTable_ = DelayedCallTable()
  }

  /**
   * Send the interest through the transport, read the entire response and call
   * onData, onTimeout or onNetworkNack as described below.
   * There are two forms of expressInterest. The first form takes the exact
   * interest (including lifetime):
   * expressInterest(interest, onData [, onTimeout] [, onNetworkNack] [, wireFormat]).
   * The second form creates the interest from a name and optional interest template:
   * expressInterest(name [, template], onData [, onTimeout] [, onNetworkNack] [, wireFormat]).
   * @param {Interest} interest The Interest to send which includes the interest
   * lifetime for the timeout.
   * @param {function} onData When a matching data packet is received, this
   * calls onData(interest, data) where interest is the interest given to
   * expressInterest and data is the received Data object. NOTE: You must not
   * change the interest object - if you need to change it then make a copy.
   * NOTE: The library will log any exceptions thrown by this callback, but for
   * better error handling the callback should catch and properly handle any
   * exceptions.
   * @param {function} onTimeout (optional) If the interest times out according
   * to the interest lifetime, this calls onTimeout(interest) where interest is
   * the interest given to expressInterest.
   * NOTE: The library will log any exceptions thrown by this callback, but for
   * better error handling the callback should catch and properly handle any
   * exceptions.
   * @param {function} onNetworkNack (optional) When a network Nack packet for
   * the interest is received and onNetworkNack is not null, this calls
   * onNetworkNack(interest, networkNack) and does not call onTimeout. interest
   * is the sent Interest and networkNack is the received NetworkNack. If
   * onNetworkNack is supplied, then onTimeout must be supplied too. However, if 
   * a network Nack is received and onNetworkNack is null, do nothing and wait
   * for the interest to time out. (Therefore, an application which does not yet
   * process a network Nack reason treats a Nack the same as a timeout.)
   * NOTE: The library will log any exceptions thrown by this callback, but for
   * better error handling the callback should catch and properly handle any
   * exceptions.
   * @param {Name} name The Name for the interest. (only used for the second
   * form of expressInterest).
   * @param {Interest} template (optional) If not omitted, copy the interest 
   * selectors from this Interest. If omitted, use a default interest lifetime.
   * (only used for the second form of expressInterest).
   * @param {WireFormat} (optional) A WireFormat object used to encode the
   * message. If omitted, use WireFormat.getDefaultWireFormat().
   * @return {integer} The pending interest ID which can be used with
   * removePendingInterest.
   * @throws string If the encoded interest size exceeds
   * Face.getMaxNdnPacketSize().
   */
  function expressInterest
    (interestOrName, arg2 = null, arg3 = null, arg4 = null, arg5 = null,
     arg6 = null)
  {
    local interestCopy;
    if (interestOrName instanceof Interest)
      // Just use a copy of the interest.
      interestCopy = Interest(interestOrName);
    else {
      // The first argument is a name. Make the interest from the name and
      // possible template.
      if (arg2 instanceof Interest) {
        local template = arg2;
        // Copy the template.
        interestCopy = Interest(template);
        interestCopy.setName(interestOrName);

        // Shift the remaining args to be processed below.
        arg2 = arg3;
        arg3 = arg4;
        arg4 = arg5;
        arg5 = arg6;
      }
      else {
        // No template.
        interestCopy = Interest(interestOrName);
        // Use a default timeout.
        interestCopy.setInterestLifetimeMilliseconds(4000.0);
      }
    }

    local onData = arg2;
    local onTimeout;
    local onNetworkNack;
    local wireFormat;
    // arg3,       arg4,          arg5 may be:
    // OnTimeout,  OnNetworkNack, WireFormat
    // OnTimeout,  OnNetworkNack, null
    // OnTimeout,  WireFormat,    null
    // OnTimeout,  null,          null
    // WireFormat, null,          null
    // null,       null,          null
    if (typeof arg3 == "function")
      onTimeout = arg3;
    else
      onTimeout = function() {};

    if (typeof arg4 == "function")
      onNetworkNack = arg4;
    else
      onNetworkNack = null;

    if (arg3 instanceof WireFormat)
      wireFormat = arg3;
    else if (arg4 instanceof WireFormat)
      wireFormat = arg4;
    else if (arg5 instanceof WireFormat)
      wireFormat = arg5;
    else
      wireFormat = WireFormat.getDefaultWireFormat();

    local pendingInterestId = getNextEntryId();

    // Set the nonce in our copy of the Interest so it is saved in the PIT.
    interestCopy.setNonce(Face.nonceTemplate_);
    interestCopy.refreshNonce();

    // TODO: Handle async connect.
    connectSync();
    expressInterestHelper_
      (pendingInterestId, interestCopy, onData, onTimeout, onNetworkNack,
       wireFormat);

    return pendingInterestId;
  }

  /**
   * Do the work of reconnectAndExpressInterest once we know we are connected.
   * Add to the pendingInterestTable_ and call transport_.send to send the
   * interest.
   * @param {integer} pendingInterestId The getNextEntryId() for the pending
   * interest ID which expressInterest got so it could return it to the caller.
   * @param {Interest} interestCopy The Interest to send, which has already
   * been copied.
   * @param {function} onData A function object to call when a matching data
   * packet is received.
   * @param {function} onTimeout A function to call if the interest times out.
   * If onTimeout is null, this does not use it.
   * @param {function} onNetworkNack A function to call when a network Nack
   * packet is received. If onNetworkNack is null, this does not use it.
   * @param {WireFormat} wireFormat A WireFormat object used to encode the
   * message.
   */
  function expressInterestHelper_
    (pendingInterestId, interestCopy, onData, onTimeout, onNetworkNack,
     wireFormat)
  {
    local pendingInterest = pendingInterestTable_.add
      (pendingInterestId, interestCopy, onData, onTimeout, onNetworkNack);
    if (pendingInterest == null)
      // removePendingInterest was already called with the pendingInterestId.
      return;

    if (onTimeout != null ||
        interestCopy.getInterestLifetimeMilliseconds() != null &&
        interestCopy.getInterestLifetimeMilliseconds() >= 0.0) {
      // Set up the timeout.
      local delayMilliseconds = interestCopy.getInterestLifetimeMilliseconds()
      if (delayMilliseconds == null || delayMilliseconds < 0.0)
        // Use a default timeout delay.
        delayMilliseconds = 4000.0;

      local thisFace = this;
      callLater
        (delayMilliseconds,
         function() { thisFace.processInterestTimeout_(pendingInterest); });
   }

    // Special case: For timeoutPrefix we don't actually send the interest.
    if (!Face.timeoutPrefix_.match(interestCopy.getName())) {
      local encoding = interestCopy.wireEncode(wireFormat);
      if (encoding.size() > Face.getMaxNdnPacketSize())
        throw
          "The encoded interest size exceeds the maximum limit getMaxNdnPacketSize()";

      transport_.send(encoding.buf());
    }
  }

  // TODO: setCommandSigningInfo
  // TODO: setCommandCertificateName
  // TODO: makeCommandInterest

  /**
   * Add an entry to the local interest filter table to call the onInterest
   * callback for a matching incoming Interest. This method only modifies the
   * library's local callback table and does not register the prefix with the
   * forwarder. It will always succeed. To register a prefix with the forwarder,
   * use registerPrefix. There are two forms of setInterestFilter.
   * The first form uses the exact given InterestFilter:
   * setInterestFilter(filter, onInterest).
   * The second form creates an InterestFilter from the given prefix Name:
   * setInterestFilter(prefix, onInterest).
   * @param {InterestFilter} filter The InterestFilter with a prefix and 
   * optional regex filter used to match the name of an incoming Interest. This
   * makes a copy of filter.
   * @param {Name} prefix The Name prefix used to match the name of an incoming
   * Interest.
   * @param {function} onInterest When an Interest is received which matches the
   * filter, this calls
   * onInterest(prefix, interest, face, interestFilterId, filter).
   * NOTE: The library will log any exceptions thrown by this callback, but for
   * better error handling the callback should catch and properly handle any
   * exceptions.
   */
  function setInterestFilter(filterOrPrefix, onInterest)
  {
    local interestFilterId = getNextEntryId();
    interestFilterTable_.setInterestFilter
      (interestFilterId, InterestFilter(filterOrPrefix), onInterest, this);
    return interestFilterId;
  }

  /**
   * The OnInterest callback calls this to put a Data packet which satisfies an
   * Interest.
   * @param {Data} data The Data packet which satisfies the interest.
   * @param {WireFormat} wireFormat (optional) A WireFormat object used to
   * encode the Data packet. If omitted, use WireFormat.getDefaultWireFormat().
   * @throws Error If the encoded Data packet size exceeds getMaxNdnPacketSize().
   */
  function putData(data, wireFormat = null)
  {
    local encoding = data.wireEncode(wireFormat);
    if (encoding.size() > Face.getMaxNdnPacketSize())
      throw
        "The encoded Data packet size exceeds the maximum limit getMaxNdnPacketSize()";

    transport_.send(encoding.buf());
  }

  /**
   * Call callbacks such as onTimeout. This returns immediately if there is
   * nothing to process. This blocks while calling the callbacks. You should
   * repeatedly call this from an event loop, with calls to sleep as needed so
   * that the loop doesn't use 100% of the CPU. Since processEvents modifies the
   * pending interest table, your application should make sure that it calls
   * processEvents in the same thread as expressInterest (which also modifies
   * the pending interest table).
   * If you call this from an main event loop, you may want to catch and
   * log/disregard all exceptions.
   */
  function processEvents()
  {
    if (doingProcessEvents_)
      // Avoid loops where a callback eventually calls processEvents again.
      return;

    doingProcessEvents_ = true;
    try {
      delayedCallTable_.callTimedOut();
      doingProcessEvents_ = false;
    } catch (ex) {
      doingProcessEvents_ = false;
      throw ex;
    }
  }

  /**
   * This is a simple form of registerPrefix to register with a local forwarder
   * where the transport (such as MicroForwarderTransport) supports "sendObject"
   * to communicate using Squirrel objects, avoiding the time and code space
   * to encode/decode control packets. Register the prefix with the forwarder
   * and call onInterest when a matching interest is received.
   * @param {Name} prefix The Name prefix.
   * @param {function} onInterest (optional) If not null, this creates an
   * interest filter from prefix so that when an Interest is received which
   * matches the filter, this calls
   * onInterest(prefix, interest, face, interestFilterId, filter).
   * NOTE: You must not change the prefix object - if you need to change it then
   * make a copy. If onInterest is null, it is ignored and you must call
   * setInterestFilter.
   * NOTE: The library will log any exceptions thrown by this callback, but for
   * better error handling the callback should catch and properly handle any
   * exceptions.
   */
  function registerPrefixUsingObject(prefix, onInterest = null)
  {
    // TODO: Handle async connect.
    connectSync();

    // TODO: Handle async register.
    transport_.sendObject({
      type = "rib/register",
      nameUri = prefix.toUri()
    });

    if (onInterest != null)
      setInterestFilter(InterestFilter(prefix), onInterest);
  }

  /**
   * Get the practical limit of the size of a network-layer packet. If a packet
   * is larger than this, the library or application MAY drop it.
   * @return {integer} The maximum NDN packet size.
   */
  static function getMaxNdnPacketSize() { return NdnCommon.MAX_NDN_PACKET_SIZE; }

  /**
   * Call callback() after the given delay. This is not part of the public API 
   * of Face.
   * @param {float} delayMilliseconds The delay in milliseconds.
   * @param {float} callback This calls callback() after the delay.
   */
  function callLater(delayMilliseconds, callback)
  {
    delayedCallTable_.callLater(delayMilliseconds, callback);
  }

  /**
   * This is used in callLater for when the pending interest expires. If the
   * pendingInterest is still in the pendingInterestTable_, remove it and call
   * its onTimeout callback.
   */
  function processInterestTimeout_(pendingInterest)
  {
    if (pendingInterestTable_.removeEntry(pendingInterest))
      pendingInterest.callTimeout();
  }

  /**
   * An internal method to get the next unique entry ID for the pending interest
   * table, interest filter table, etc. Most entry IDs are for the pending
   * interest table (there usually are not many interest filter table entries)
   * so we use a common pool to only have to have one method which is called by
   * Face.
   *
   * @return {integer} The next entry ID.
   */
  function getNextEntryId() { return ++lastEntryId_; }

  /**
   * If connectionStatus_ is not already CONNECT_COMPLETE, do a synchronous
   * transport_connect and set the status to CONNECT_COMPLETE.
   */
  function connectSync()
  {
    if (connectStatus_ != FaceConnectStatus_.CONNECT_COMPLETE) {
      transport_.connect(connectionInfo_, this, null);
      connectStatus_ = FaceConnectStatus_.CONNECT_COMPLETE;
    }
  }

  /**
   * This is called by the transport's ElementReader to process an entire
   * received element such as a Data or Interest packet.
   * @param {Buffer} element The bytes of the incoming element.
   */
  function onReceivedElement(element)
  {
    // Clear timed-out Interests in case the application doesn't call processEvents.
    processEvents();

    local lpPacket = null;
    // Use Buffer.get to avoid using the metamethod.
    if (element.get(0) == Tlv.LpPacket_LpPacket)
      // TODO: Support LpPacket.
      throw "not supported";

    // First, decode as Interest or Data.
    local interest = null;
    local data = null;
    if (element.get(0) == Tlv.Interest || element.get(0) == Tlv.Data) {
      local decoder = TlvDecoder (element);
      if (decoder.peekType(Tlv.Interest, element.len())) {
        interest = Interest();
        interest.wireDecode(element, TlvWireFormat.get());

        if (lpPacket != null)
          interest.setLpPacket(lpPacket);
      }
      else if (decoder.peekType(Tlv.Data, element.len())) {
        data = Data();
        data.wireDecode(element, TlvWireFormat.get());

        if (lpPacket != null)
          data.setLpPacket(lpPacket);
      }
    }

    if (lpPacket != null) {
      // We have decoded the fragment, so remove the wire encoding to save memory.
      lpPacket.setFragmentWireEncoding(Blob());

      // TODO: Check for NetworkNack.
    }

    // Now process as Interest or Data.
    if (interest != null) {
      // Call all interest filter callbacks which match.
      local matchedFilters = [];
      interestFilterTable_.getMatchedFilters(interest, matchedFilters);
      foreach (entry in matchedFilters) {
        try {
          entry.getOnInterest()
            (entry.getFilter().getPrefix(), interest, this,
             entry.getInterestFilterId(), entry.getFilter());
        } catch (ex) {
          consoleLog("<DBUG>Error in onInterest: " + ex + "</DBUG>");
        }
      }
    }
    else if (data != null) {
      local pendingInterests = [];
      pendingInterestTable_.extractEntriesForExpressedInterest
        (data, pendingInterests);
      // Process each matching PIT entry (if any).
      foreach (pendingInterest in pendingInterests) {
        try {
          pendingInterest.getOnData()(pendingInterest.getInterest(), data);
        } catch (ex) {
          consoleLog("<DBUG>Error in onData: " + ex + "</DBUG>");
        }
      }
    }
  }
}
/*
 * This file is part of aes-squirrel.
 *
 * Based on aes-js: https://github.com/ricmoo/aes-js
 *
 * (c) 2015 Richard Moore
 * (c) 2016 KISI Inc.
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

/**
 * Convert the raw string to an array of 8-bit integers.
 */
function rawToByteArray(str)
{
  local arr = array(str.len());
  for (local i = 0; i < str.len(); ++i)
    arr[i] = str[i] & 0xff;

  return arr;
}

/**
 * Convert the raw string to an array of 32-bit integers.
 */
function rawToIntArray(str)
{
  local arr = array(str.len() / 4);
  local j = 0;
  for (local i = 0; i < str.len(); i += 4)
    arr[j++] = ((str[i + 0] & 0xff) << 24) |
               ((str[i + 1] & 0xff) << 16) |
               ((str[i + 2] & 0xff) << 8) |
               (str[i + 3] & 0xff);

  return arr;
}

class AES {

  // Number of rounds by keysize
  static numberOfRounds = { "16": 10, "24": 12, "32": 14 }

  // Note: To use less program space, store raw strings and convert to arrays.
  // Round constant words
  static rcon = rawToByteArray("\x01\x02\x04\x08\x10\x20\x40\x80\x1b\x36\x6c\xd8\xab\x4d\x9a\x2f\x5e\xbc\x63\xc6\x97\x35\x6a\xd4\xb3\x7d\xfa\xef\xc5\x91");

  // S-box and Inverse S-box (S is for Substitution)
  static S = rawToByteArray("\x63\x7c\x77\x7b\xf2\x6b\x6f\xc5\x30\x01\x67\x2b\xfe\xd7\xab\x76\xca\x82\xc9\x7d\xfa\x59\x47\xf0\xad\xd4\xa2\xaf\x9c\xa4\x72\xc0\xb7\xfd\x93\x26\x36\x3f\xf7\xcc\x34\xa5\xe5\xf1\x71\xd8\x31\x15\x04\xc7\x23\xc3\x18\x96\x05\x9a\x07\x12\x80\xe2\xeb\x27\xb2\x75\x09\x83\x2c\x1a\x1b\x6e\x5a\xa0\x52\x3b\xd6\xb3\x29\xe3\x2f\x84\x53\xd1\x00\xed\x20\xfc\xb1\x5b\x6a\xcb\xbe\x39\x4a\x4c\x58\xcf\xd0\xef\xaa\xfb\x43\x4d\x33\x85\x45\xf9\x02\x7f\x50\x3c\x9f\xa8\x51\xa3\x40\x8f\x92\x9d\x38\xf5\xbc\xb6\xda\x21\x10\xff\xf3\xd2\xcd\x0c\x13\xec\x5f\x97\x44\x17\xc4\xa7\x7e\x3d\x64\x5d\x19\x73\x60\x81\x4f\xdc\x22\x2a\x90\x88\x46\xee\xb8\x14\xde\x5e\x0b\xdb\xe0\x32\x3a\x0a\x49\x06\x24\x5c\xc2\xd3\xac\x62\x91\x95\xe4\x79\xe7\xc8\x37\x6d\x8d\xd5\x4e\xa9\x6c\x56\xf4\xea\x65\x7a\xae\x08\xba\x78\x25\x2e\x1c\xa6\xb4\xc6\xe8\xdd\x74\x1f\x4b\xbd\x8b\x8a\x70\x3e\xb5\x66\x48\x03\xf6\x0e\x61\x35\x57\xb9\x86\xc1\x1d\x9e\xe1\xf8\x98\x11\x69\xd9\x8e\x94\x9b\x1e\x87\xe9\xce\x55\x28\xdf\x8c\xa1\x89\x0d\xbf\xe6\x42\x68\x41\x99\x2d\x0f\xb0\x54\xbb\x16");
  static Si =rawToByteArray("\x52\x09\x6a\xd5\x30\x36\xa5\x38\xbf\x40\xa3\x9e\x81\xf3\xd7\xfb\x7c\xe3\x39\x82\x9b\x2f\xff\x87\x34\x8e\x43\x44\xc4\xde\xe9\xcb\x54\x7b\x94\x32\xa6\xc2\x23\x3d\xee\x4c\x95\x0b\x42\xfa\xc3\x4e\x08\x2e\xa1\x66\x28\xd9\x24\xb2\x76\x5b\xa2\x49\x6d\x8b\xd1\x25\x72\xf8\xf6\x64\x86\x68\x98\x16\xd4\xa4\x5c\xcc\x5d\x65\xb6\x92\x6c\x70\x48\x50\xfd\xed\xb9\xda\x5e\x15\x46\x57\xa7\x8d\x9d\x84\x90\xd8\xab\x00\x8c\xbc\xd3\x0a\xf7\xe4\x58\x05\xb8\xb3\x45\x06\xd0\x2c\x1e\x8f\xca\x3f\x0f\x02\xc1\xaf\xbd\x03\x01\x13\x8a\x6b\x3a\x91\x11\x41\x4f\x67\xdc\xea\x97\xf2\xcf\xce\xf0\xb4\xe6\x73\x96\xac\x74\x22\xe7\xad\x35\x85\xe2\xf9\x37\xe8\x1c\x75\xdf\x6e\x47\xf1\x1a\x71\x1d\x29\xc5\x89\x6f\xb7\x62\x0e\xaa\x18\xbe\x1b\xfc\x56\x3e\x4b\xc6\xd2\x79\x20\x9a\xdb\xc0\xfe\x78\xcd\x5a\xf4\x1f\xdd\xa8\x33\x88\x07\xc7\x31\xb1\x12\x10\x59\x27\x80\xec\x5f\x60\x51\x7f\xa9\x19\xb5\x4a\x0d\x2d\xe5\x7a\x9f\x93\xc9\x9c\xef\xa0\xe0\x3b\x4d\xae\x2a\xf5\xb0\xc8\xeb\xbb\x3c\x83\x53\x99\x61\x17\x2b\x04\x7e\xba\x77\xd6\x26\xe1\x69\x14\x63\x55\x21\x0c\x7d");

  // Transformations for encryption
  static T1 = rawToIntArray("\xc6\x63\x63\xa5\xf8\x7c\x7c\x84\xee\x77\x77\x99\xf6\x7b\x7b\x8d\xff\xf2\xf2\x0d\xd6\x6b\x6b\xbd\xde\x6f\x6f\xb1\x91\xc5\xc5\x54\x60\x30\x30\x50\x02\x01\x01\x03\xce\x67\x67\xa9\x56\x2b\x2b\x7d\xe7\xfe\xfe\x19\xb5\xd7\xd7\x62\x4d\xab\xab\xe6\xec\x76\x76\x9a\x8f\xca\xca\x45\x1f\x82\x82\x9d\x89\xc9\xc9\x40\xfa\x7d\x7d\x87\xef\xfa\xfa\x15\xb2\x59\x59\xeb\x8e\x47\x47\xc9\xfb\xf0\xf0\x0b\x41\xad\xad\xec\xb3\xd4\xd4\x67\x5f\xa2\xa2\xfd\x45\xaf\xaf\xea\x23\x9c\x9c\xbf\x53\xa4\xa4\xf7\xe4\x72\x72\x96\x9b\xc0\xc0\x5b\x75\xb7\xb7\xc2\xe1\xfd\xfd\x1c\x3d\x93\x93\xae\x4c\x26\x26\x6a\x6c\x36\x36\x5a\x7e\x3f\x3f\x41\xf5\xf7\xf7\x02\x83\xcc\xcc\x4f\x68\x34\x34\x5c\x51\xa5\xa5\xf4\xd1\xe5\xe5\x34\xf9\xf1\xf1\x08\xe2\x71\x71\x93\xab\xd8\xd8\x73\x62\x31\x31\x53\x2a\x15\x15\x3f\x08\x04\x04\x0c\x95\xc7\xc7\x52\x46\x23\x23\x65\x9d\xc3\xc3\x5e\x30\x18\x18\x28\x37\x96\x96\xa1\x0a\x05\x05\x0f\x2f\x9a\x9a\xb5\x0e\x07\x07\x09\x24\x12\x12\x36\x1b\x80\x80\x9b\xdf\xe2\xe2\x3d\xcd\xeb\xeb\x26\x4e\x27\x27\x69\x7f\xb2\xb2\xcd\xea\x75\x75\x9f\x12\x09\x09\x1b\x1d\x83\x83\x9e\x58\x2c\x2c\x74\x34\x1a\x1a\x2e\x36\x1b\x1b\x2d\xdc\x6e\x6e\xb2\xb4\x5a\x5a\xee\x5b\xa0\xa0\xfb\xa4\x52\x52\xf6\x76\x3b\x3b\x4d\xb7\xd6\xd6\x61\x7d\xb3\xb3\xce\x52\x29\x29\x7b\xdd\xe3\xe3\x3e\x5e\x2f\x2f\x71\x13\x84\x84\x97\xa6\x53\x53\xf5\xb9\xd1\xd1\x68\x00\x00\x00\x00\xc1\xed\xed\x2c\x40\x20\x20\x60\xe3\xfc\xfc\x1f\x79\xb1\xb1\xc8\xb6\x5b\x5b\xed\xd4\x6a\x6a\xbe\x8d\xcb\xcb\x46\x67\xbe\xbe\xd9\x72\x39\x39\x4b\x94\x4a\x4a\xde\x98\x4c\x4c\xd4\xb0\x58\x58\xe8\x85\xcf\xcf\x4a\xbb\xd0\xd0\x6b\xc5\xef\xef\x2a\x4f\xaa\xaa\xe5\xed\xfb\xfb\x16\x86\x43\x43\xc5\x9a\x4d\x4d\xd7\x66\x33\x33\x55\x11\x85\x85\x94\x8a\x45\x45\xcf\xe9\xf9\xf9\x10\x04\x02\x02\x06\xfe\x7f\x7f\x81\xa0\x50\x50\xf0\x78\x3c\x3c\x44\x25\x9f\x9f\xba\x4b\xa8\xa8\xe3\xa2\x51\x51\xf3\x5d\xa3\xa3\xfe\x80\x40\x40\xc0\x05\x8f\x8f\x8a\x3f\x92\x92\xad\x21\x9d\x9d\xbc\x70\x38\x38\x48\xf1\xf5\xf5\x04\x63\xbc\xbc\xdf\x77\xb6\xb6\xc1\xaf\xda\xda\x75\x42\x21\x21\x63\x20\x10\x10\x30\xe5\xff\xff\x1a\xfd\xf3\xf3\x0e\xbf\xd2\xd2\x6d\x81\xcd\xcd\x4c\x18\x0c\x0c\x14\x26\x13\x13\x35\xc3\xec\xec\x2f\xbe\x5f\x5f\xe1\x35\x97\x97\xa2\x88\x44\x44\xcc\x2e\x17\x17\x39\x93\xc4\xc4\x57\x55\xa7\xa7\xf2\xfc\x7e\x7e\x82\x7a\x3d\x3d\x47\xc8\x64\x64\xac\xba\x5d\x5d\xe7\x32\x19\x19\x2b\xe6\x73\x73\x95\xc0\x60\x60\xa0\x19\x81\x81\x98\x9e\x4f\x4f\xd1\xa3\xdc\xdc\x7f\x44\x22\x22\x66\x54\x2a\x2a\x7e\x3b\x90\x90\xab\x0b\x88\x88\x83\x8c\x46\x46\xca\xc7\xee\xee\x29\x6b\xb8\xb8\xd3\x28\x14\x14\x3c\xa7\xde\xde\x79\xbc\x5e\x5e\xe2\x16\x0b\x0b\x1d\xad\xdb\xdb\x76\xdb\xe0\xe0\x3b\x64\x32\x32\x56\x74\x3a\x3a\x4e\x14\x0a\x0a\x1e\x92\x49\x49\xdb\x0c\x06\x06\x0a\x48\x24\x24\x6c\xb8\x5c\x5c\xe4\x9f\xc2\xc2\x5d\xbd\xd3\xd3\x6e\x43\xac\xac\xef\xc4\x62\x62\xa6\x39\x91\x91\xa8\x31\x95\x95\xa4\xd3\xe4\xe4\x37\xf2\x79\x79\x8b\xd5\xe7\xe7\x32\x8b\xc8\xc8\x43\x6e\x37\x37\x59\xda\x6d\x6d\xb7\x01\x8d\x8d\x8c\xb1\xd5\xd5\x64\x9c\x4e\x4e\xd2\x49\xa9\xa9\xe0\xd8\x6c\x6c\xb4\xac\x56\x56\xfa\xf3\xf4\xf4\x07\xcf\xea\xea\x25\xca\x65\x65\xaf\xf4\x7a\x7a\x8e\x47\xae\xae\xe9\x10\x08\x08\x18\x6f\xba\xba\xd5\xf0\x78\x78\x88\x4a\x25\x25\x6f\x5c\x2e\x2e\x72\x38\x1c\x1c\x24\x57\xa6\xa6\xf1\x73\xb4\xb4\xc7\x97\xc6\xc6\x51\xcb\xe8\xe8\x23\xa1\xdd\xdd\x7c\xe8\x74\x74\x9c\x3e\x1f\x1f\x21\x96\x4b\x4b\xdd\x61\xbd\xbd\xdc\x0d\x8b\x8b\x86\x0f\x8a\x8a\x85\xe0\x70\x70\x90\x7c\x3e\x3e\x42\x71\xb5\xb5\xc4\xcc\x66\x66\xaa\x90\x48\x48\xd8\x06\x03\x03\x05\xf7\xf6\xf6\x01\x1c\x0e\x0e\x12\xc2\x61\x61\xa3\x6a\x35\x35\x5f\xae\x57\x57\xf9\x69\xb9\xb9\xd0\x17\x86\x86\x91\x99\xc1\xc1\x58\x3a\x1d\x1d\x27\x27\x9e\x9e\xb9\xd9\xe1\xe1\x38\xeb\xf8\xf8\x13\x2b\x98\x98\xb3\x22\x11\x11\x33\xd2\x69\x69\xbb\xa9\xd9\xd9\x70\x07\x8e\x8e\x89\x33\x94\x94\xa7\x2d\x9b\x9b\xb6\x3c\x1e\x1e\x22\x15\x87\x87\x92\xc9\xe9\xe9\x20\x87\xce\xce\x49\xaa\x55\x55\xff\x50\x28\x28\x78\xa5\xdf\xdf\x7a\x03\x8c\x8c\x8f\x59\xa1\xa1\xf8\x09\x89\x89\x80\x1a\x0d\x0d\x17\x65\xbf\xbf\xda\xd7\xe6\xe6\x31\x84\x42\x42\xc6\xd0\x68\x68\xb8\x82\x41\x41\xc3\x29\x99\x99\xb0\x5a\x2d\x2d\x77\x1e\x0f\x0f\x11\x7b\xb0\xb0\xcb\xa8\x54\x54\xfc\x6d\xbb\xbb\xd6\x2c\x16\x16\x3a");
  static T2 = rawToIntArray("\xa5\xc6\x63\x63\x84\xf8\x7c\x7c\x99\xee\x77\x77\x8d\xf6\x7b\x7b\x0d\xff\xf2\xf2\xbd\xd6\x6b\x6b\xb1\xde\x6f\x6f\x54\x91\xc5\xc5\x50\x60\x30\x30\x03\x02\x01\x01\xa9\xce\x67\x67\x7d\x56\x2b\x2b\x19\xe7\xfe\xfe\x62\xb5\xd7\xd7\xe6\x4d\xab\xab\x9a\xec\x76\x76\x45\x8f\xca\xca\x9d\x1f\x82\x82\x40\x89\xc9\xc9\x87\xfa\x7d\x7d\x15\xef\xfa\xfa\xeb\xb2\x59\x59\xc9\x8e\x47\x47\x0b\xfb\xf0\xf0\xec\x41\xad\xad\x67\xb3\xd4\xd4\xfd\x5f\xa2\xa2\xea\x45\xaf\xaf\xbf\x23\x9c\x9c\xf7\x53\xa4\xa4\x96\xe4\x72\x72\x5b\x9b\xc0\xc0\xc2\x75\xb7\xb7\x1c\xe1\xfd\xfd\xae\x3d\x93\x93\x6a\x4c\x26\x26\x5a\x6c\x36\x36\x41\x7e\x3f\x3f\x02\xf5\xf7\xf7\x4f\x83\xcc\xcc\x5c\x68\x34\x34\xf4\x51\xa5\xa5\x34\xd1\xe5\xe5\x08\xf9\xf1\xf1\x93\xe2\x71\x71\x73\xab\xd8\xd8\x53\x62\x31\x31\x3f\x2a\x15\x15\x0c\x08\x04\x04\x52\x95\xc7\xc7\x65\x46\x23\x23\x5e\x9d\xc3\xc3\x28\x30\x18\x18\xa1\x37\x96\x96\x0f\x0a\x05\x05\xb5\x2f\x9a\x9a\x09\x0e\x07\x07\x36\x24\x12\x12\x9b\x1b\x80\x80\x3d\xdf\xe2\xe2\x26\xcd\xeb\xeb\x69\x4e\x27\x27\xcd\x7f\xb2\xb2\x9f\xea\x75\x75\x1b\x12\x09\x09\x9e\x1d\x83\x83\x74\x58\x2c\x2c\x2e\x34\x1a\x1a\x2d\x36\x1b\x1b\xb2\xdc\x6e\x6e\xee\xb4\x5a\x5a\xfb\x5b\xa0\xa0\xf6\xa4\x52\x52\x4d\x76\x3b\x3b\x61\xb7\xd6\xd6\xce\x7d\xb3\xb3\x7b\x52\x29\x29\x3e\xdd\xe3\xe3\x71\x5e\x2f\x2f\x97\x13\x84\x84\xf5\xa6\x53\x53\x68\xb9\xd1\xd1\x00\x00\x00\x00\x2c\xc1\xed\xed\x60\x40\x20\x20\x1f\xe3\xfc\xfc\xc8\x79\xb1\xb1\xed\xb6\x5b\x5b\xbe\xd4\x6a\x6a\x46\x8d\xcb\xcb\xd9\x67\xbe\xbe\x4b\x72\x39\x39\xde\x94\x4a\x4a\xd4\x98\x4c\x4c\xe8\xb0\x58\x58\x4a\x85\xcf\xcf\x6b\xbb\xd0\xd0\x2a\xc5\xef\xef\xe5\x4f\xaa\xaa\x16\xed\xfb\xfb\xc5\x86\x43\x43\xd7\x9a\x4d\x4d\x55\x66\x33\x33\x94\x11\x85\x85\xcf\x8a\x45\x45\x10\xe9\xf9\xf9\x06\x04\x02\x02\x81\xfe\x7f\x7f\xf0\xa0\x50\x50\x44\x78\x3c\x3c\xba\x25\x9f\x9f\xe3\x4b\xa8\xa8\xf3\xa2\x51\x51\xfe\x5d\xa3\xa3\xc0\x80\x40\x40\x8a\x05\x8f\x8f\xad\x3f\x92\x92\xbc\x21\x9d\x9d\x48\x70\x38\x38\x04\xf1\xf5\xf5\xdf\x63\xbc\xbc\xc1\x77\xb6\xb6\x75\xaf\xda\xda\x63\x42\x21\x21\x30\x20\x10\x10\x1a\xe5\xff\xff\x0e\xfd\xf3\xf3\x6d\xbf\xd2\xd2\x4c\x81\xcd\xcd\x14\x18\x0c\x0c\x35\x26\x13\x13\x2f\xc3\xec\xec\xe1\xbe\x5f\x5f\xa2\x35\x97\x97\xcc\x88\x44\x44\x39\x2e\x17\x17\x57\x93\xc4\xc4\xf2\x55\xa7\xa7\x82\xfc\x7e\x7e\x47\x7a\x3d\x3d\xac\xc8\x64\x64\xe7\xba\x5d\x5d\x2b\x32\x19\x19\x95\xe6\x73\x73\xa0\xc0\x60\x60\x98\x19\x81\x81\xd1\x9e\x4f\x4f\x7f\xa3\xdc\xdc\x66\x44\x22\x22\x7e\x54\x2a\x2a\xab\x3b\x90\x90\x83\x0b\x88\x88\xca\x8c\x46\x46\x29\xc7\xee\xee\xd3\x6b\xb8\xb8\x3c\x28\x14\x14\x79\xa7\xde\xde\xe2\xbc\x5e\x5e\x1d\x16\x0b\x0b\x76\xad\xdb\xdb\x3b\xdb\xe0\xe0\x56\x64\x32\x32\x4e\x74\x3a\x3a\x1e\x14\x0a\x0a\xdb\x92\x49\x49\x0a\x0c\x06\x06\x6c\x48\x24\x24\xe4\xb8\x5c\x5c\x5d\x9f\xc2\xc2\x6e\xbd\xd3\xd3\xef\x43\xac\xac\xa6\xc4\x62\x62\xa8\x39\x91\x91\xa4\x31\x95\x95\x37\xd3\xe4\xe4\x8b\xf2\x79\x79\x32\xd5\xe7\xe7\x43\x8b\xc8\xc8\x59\x6e\x37\x37\xb7\xda\x6d\x6d\x8c\x01\x8d\x8d\x64\xb1\xd5\xd5\xd2\x9c\x4e\x4e\xe0\x49\xa9\xa9\xb4\xd8\x6c\x6c\xfa\xac\x56\x56\x07\xf3\xf4\xf4\x25\xcf\xea\xea\xaf\xca\x65\x65\x8e\xf4\x7a\x7a\xe9\x47\xae\xae\x18\x10\x08\x08\xd5\x6f\xba\xba\x88\xf0\x78\x78\x6f\x4a\x25\x25\x72\x5c\x2e\x2e\x24\x38\x1c\x1c\xf1\x57\xa6\xa6\xc7\x73\xb4\xb4\x51\x97\xc6\xc6\x23\xcb\xe8\xe8\x7c\xa1\xdd\xdd\x9c\xe8\x74\x74\x21\x3e\x1f\x1f\xdd\x96\x4b\x4b\xdc\x61\xbd\xbd\x86\x0d\x8b\x8b\x85\x0f\x8a\x8a\x90\xe0\x70\x70\x42\x7c\x3e\x3e\xc4\x71\xb5\xb5\xaa\xcc\x66\x66\xd8\x90\x48\x48\x05\x06\x03\x03\x01\xf7\xf6\xf6\x12\x1c\x0e\x0e\xa3\xc2\x61\x61\x5f\x6a\x35\x35\xf9\xae\x57\x57\xd0\x69\xb9\xb9\x91\x17\x86\x86\x58\x99\xc1\xc1\x27\x3a\x1d\x1d\xb9\x27\x9e\x9e\x38\xd9\xe1\xe1\x13\xeb\xf8\xf8\xb3\x2b\x98\x98\x33\x22\x11\x11\xbb\xd2\x69\x69\x70\xa9\xd9\xd9\x89\x07\x8e\x8e\xa7\x33\x94\x94\xb6\x2d\x9b\x9b\x22\x3c\x1e\x1e\x92\x15\x87\x87\x20\xc9\xe9\xe9\x49\x87\xce\xce\xff\xaa\x55\x55\x78\x50\x28\x28\x7a\xa5\xdf\xdf\x8f\x03\x8c\x8c\xf8\x59\xa1\xa1\x80\x09\x89\x89\x17\x1a\x0d\x0d\xda\x65\xbf\xbf\x31\xd7\xe6\xe6\xc6\x84\x42\x42\xb8\xd0\x68\x68\xc3\x82\x41\x41\xb0\x29\x99\x99\x77\x5a\x2d\x2d\x11\x1e\x0f\x0f\xcb\x7b\xb0\xb0\xfc\xa8\x54\x54\xd6\x6d\xbb\xbb\x3a\x2c\x16\x16");
  static T3 = rawToIntArray("\x63\xa5\xc6\x63\x7c\x84\xf8\x7c\x77\x99\xee\x77\x7b\x8d\xf6\x7b\xf2\x0d\xff\xf2\x6b\xbd\xd6\x6b\x6f\xb1\xde\x6f\xc5\x54\x91\xc5\x30\x50\x60\x30\x01\x03\x02\x01\x67\xa9\xce\x67\x2b\x7d\x56\x2b\xfe\x19\xe7\xfe\xd7\x62\xb5\xd7\xab\xe6\x4d\xab\x76\x9a\xec\x76\xca\x45\x8f\xca\x82\x9d\x1f\x82\xc9\x40\x89\xc9\x7d\x87\xfa\x7d\xfa\x15\xef\xfa\x59\xeb\xb2\x59\x47\xc9\x8e\x47\xf0\x0b\xfb\xf0\xad\xec\x41\xad\xd4\x67\xb3\xd4\xa2\xfd\x5f\xa2\xaf\xea\x45\xaf\x9c\xbf\x23\x9c\xa4\xf7\x53\xa4\x72\x96\xe4\x72\xc0\x5b\x9b\xc0\xb7\xc2\x75\xb7\xfd\x1c\xe1\xfd\x93\xae\x3d\x93\x26\x6a\x4c\x26\x36\x5a\x6c\x36\x3f\x41\x7e\x3f\xf7\x02\xf5\xf7\xcc\x4f\x83\xcc\x34\x5c\x68\x34\xa5\xf4\x51\xa5\xe5\x34\xd1\xe5\xf1\x08\xf9\xf1\x71\x93\xe2\x71\xd8\x73\xab\xd8\x31\x53\x62\x31\x15\x3f\x2a\x15\x04\x0c\x08\x04\xc7\x52\x95\xc7\x23\x65\x46\x23\xc3\x5e\x9d\xc3\x18\x28\x30\x18\x96\xa1\x37\x96\x05\x0f\x0a\x05\x9a\xb5\x2f\x9a\x07\x09\x0e\x07\x12\x36\x24\x12\x80\x9b\x1b\x80\xe2\x3d\xdf\xe2\xeb\x26\xcd\xeb\x27\x69\x4e\x27\xb2\xcd\x7f\xb2\x75\x9f\xea\x75\x09\x1b\x12\x09\x83\x9e\x1d\x83\x2c\x74\x58\x2c\x1a\x2e\x34\x1a\x1b\x2d\x36\x1b\x6e\xb2\xdc\x6e\x5a\xee\xb4\x5a\xa0\xfb\x5b\xa0\x52\xf6\xa4\x52\x3b\x4d\x76\x3b\xd6\x61\xb7\xd6\xb3\xce\x7d\xb3\x29\x7b\x52\x29\xe3\x3e\xdd\xe3\x2f\x71\x5e\x2f\x84\x97\x13\x84\x53\xf5\xa6\x53\xd1\x68\xb9\xd1\x00\x00\x00\x00\xed\x2c\xc1\xed\x20\x60\x40\x20\xfc\x1f\xe3\xfc\xb1\xc8\x79\xb1\x5b\xed\xb6\x5b\x6a\xbe\xd4\x6a\xcb\x46\x8d\xcb\xbe\xd9\x67\xbe\x39\x4b\x72\x39\x4a\xde\x94\x4a\x4c\xd4\x98\x4c\x58\xe8\xb0\x58\xcf\x4a\x85\xcf\xd0\x6b\xbb\xd0\xef\x2a\xc5\xef\xaa\xe5\x4f\xaa\xfb\x16\xed\xfb\x43\xc5\x86\x43\x4d\xd7\x9a\x4d\x33\x55\x66\x33\x85\x94\x11\x85\x45\xcf\x8a\x45\xf9\x10\xe9\xf9\x02\x06\x04\x02\x7f\x81\xfe\x7f\x50\xf0\xa0\x50\x3c\x44\x78\x3c\x9f\xba\x25\x9f\xa8\xe3\x4b\xa8\x51\xf3\xa2\x51\xa3\xfe\x5d\xa3\x40\xc0\x80\x40\x8f\x8a\x05\x8f\x92\xad\x3f\x92\x9d\xbc\x21\x9d\x38\x48\x70\x38\xf5\x04\xf1\xf5\xbc\xdf\x63\xbc\xb6\xc1\x77\xb6\xda\x75\xaf\xda\x21\x63\x42\x21\x10\x30\x20\x10\xff\x1a\xe5\xff\xf3\x0e\xfd\xf3\xd2\x6d\xbf\xd2\xcd\x4c\x81\xcd\x0c\x14\x18\x0c\x13\x35\x26\x13\xec\x2f\xc3\xec\x5f\xe1\xbe\x5f\x97\xa2\x35\x97\x44\xcc\x88\x44\x17\x39\x2e\x17\xc4\x57\x93\xc4\xa7\xf2\x55\xa7\x7e\x82\xfc\x7e\x3d\x47\x7a\x3d\x64\xac\xc8\x64\x5d\xe7\xba\x5d\x19\x2b\x32\x19\x73\x95\xe6\x73\x60\xa0\xc0\x60\x81\x98\x19\x81\x4f\xd1\x9e\x4f\xdc\x7f\xa3\xdc\x22\x66\x44\x22\x2a\x7e\x54\x2a\x90\xab\x3b\x90\x88\x83\x0b\x88\x46\xca\x8c\x46\xee\x29\xc7\xee\xb8\xd3\x6b\xb8\x14\x3c\x28\x14\xde\x79\xa7\xde\x5e\xe2\xbc\x5e\x0b\x1d\x16\x0b\xdb\x76\xad\xdb\xe0\x3b\xdb\xe0\x32\x56\x64\x32\x3a\x4e\x74\x3a\x0a\x1e\x14\x0a\x49\xdb\x92\x49\x06\x0a\x0c\x06\x24\x6c\x48\x24\x5c\xe4\xb8\x5c\xc2\x5d\x9f\xc2\xd3\x6e\xbd\xd3\xac\xef\x43\xac\x62\xa6\xc4\x62\x91\xa8\x39\x91\x95\xa4\x31\x95\xe4\x37\xd3\xe4\x79\x8b\xf2\x79\xe7\x32\xd5\xe7\xc8\x43\x8b\xc8\x37\x59\x6e\x37\x6d\xb7\xda\x6d\x8d\x8c\x01\x8d\xd5\x64\xb1\xd5\x4e\xd2\x9c\x4e\xa9\xe0\x49\xa9\x6c\xb4\xd8\x6c\x56\xfa\xac\x56\xf4\x07\xf3\xf4\xea\x25\xcf\xea\x65\xaf\xca\x65\x7a\x8e\xf4\x7a\xae\xe9\x47\xae\x08\x18\x10\x08\xba\xd5\x6f\xba\x78\x88\xf0\x78\x25\x6f\x4a\x25\x2e\x72\x5c\x2e\x1c\x24\x38\x1c\xa6\xf1\x57\xa6\xb4\xc7\x73\xb4\xc6\x51\x97\xc6\xe8\x23\xcb\xe8\xdd\x7c\xa1\xdd\x74\x9c\xe8\x74\x1f\x21\x3e\x1f\x4b\xdd\x96\x4b\xbd\xdc\x61\xbd\x8b\x86\x0d\x8b\x8a\x85\x0f\x8a\x70\x90\xe0\x70\x3e\x42\x7c\x3e\xb5\xc4\x71\xb5\x66\xaa\xcc\x66\x48\xd8\x90\x48\x03\x05\x06\x03\xf6\x01\xf7\xf6\x0e\x12\x1c\x0e\x61\xa3\xc2\x61\x35\x5f\x6a\x35\x57\xf9\xae\x57\xb9\xd0\x69\xb9\x86\x91\x17\x86\xc1\x58\x99\xc1\x1d\x27\x3a\x1d\x9e\xb9\x27\x9e\xe1\x38\xd9\xe1\xf8\x13\xeb\xf8\x98\xb3\x2b\x98\x11\x33\x22\x11\x69\xbb\xd2\x69\xd9\x70\xa9\xd9\x8e\x89\x07\x8e\x94\xa7\x33\x94\x9b\xb6\x2d\x9b\x1e\x22\x3c\x1e\x87\x92\x15\x87\xe9\x20\xc9\xe9\xce\x49\x87\xce\x55\xff\xaa\x55\x28\x78\x50\x28\xdf\x7a\xa5\xdf\x8c\x8f\x03\x8c\xa1\xf8\x59\xa1\x89\x80\x09\x89\x0d\x17\x1a\x0d\xbf\xda\x65\xbf\xe6\x31\xd7\xe6\x42\xc6\x84\x42\x68\xb8\xd0\x68\x41\xc3\x82\x41\x99\xb0\x29\x99\x2d\x77\x5a\x2d\x0f\x11\x1e\x0f\xb0\xcb\x7b\xb0\x54\xfc\xa8\x54\xbb\xd6\x6d\xbb\x16\x3a\x2c\x16");
  static T4 = rawToIntArray("\x63\x63\xa5\xc6\x7c\x7c\x84\xf8\x77\x77\x99\xee\x7b\x7b\x8d\xf6\xf2\xf2\x0d\xff\x6b\x6b\xbd\xd6\x6f\x6f\xb1\xde\xc5\xc5\x54\x91\x30\x30\x50\x60\x01\x01\x03\x02\x67\x67\xa9\xce\x2b\x2b\x7d\x56\xfe\xfe\x19\xe7\xd7\xd7\x62\xb5\xab\xab\xe6\x4d\x76\x76\x9a\xec\xca\xca\x45\x8f\x82\x82\x9d\x1f\xc9\xc9\x40\x89\x7d\x7d\x87\xfa\xfa\xfa\x15\xef\x59\x59\xeb\xb2\x47\x47\xc9\x8e\xf0\xf0\x0b\xfb\xad\xad\xec\x41\xd4\xd4\x67\xb3\xa2\xa2\xfd\x5f\xaf\xaf\xea\x45\x9c\x9c\xbf\x23\xa4\xa4\xf7\x53\x72\x72\x96\xe4\xc0\xc0\x5b\x9b\xb7\xb7\xc2\x75\xfd\xfd\x1c\xe1\x93\x93\xae\x3d\x26\x26\x6a\x4c\x36\x36\x5a\x6c\x3f\x3f\x41\x7e\xf7\xf7\x02\xf5\xcc\xcc\x4f\x83\x34\x34\x5c\x68\xa5\xa5\xf4\x51\xe5\xe5\x34\xd1\xf1\xf1\x08\xf9\x71\x71\x93\xe2\xd8\xd8\x73\xab\x31\x31\x53\x62\x15\x15\x3f\x2a\x04\x04\x0c\x08\xc7\xc7\x52\x95\x23\x23\x65\x46\xc3\xc3\x5e\x9d\x18\x18\x28\x30\x96\x96\xa1\x37\x05\x05\x0f\x0a\x9a\x9a\xb5\x2f\x07\x07\x09\x0e\x12\x12\x36\x24\x80\x80\x9b\x1b\xe2\xe2\x3d\xdf\xeb\xeb\x26\xcd\x27\x27\x69\x4e\xb2\xb2\xcd\x7f\x75\x75\x9f\xea\x09\x09\x1b\x12\x83\x83\x9e\x1d\x2c\x2c\x74\x58\x1a\x1a\x2e\x34\x1b\x1b\x2d\x36\x6e\x6e\xb2\xdc\x5a\x5a\xee\xb4\xa0\xa0\xfb\x5b\x52\x52\xf6\xa4\x3b\x3b\x4d\x76\xd6\xd6\x61\xb7\xb3\xb3\xce\x7d\x29\x29\x7b\x52\xe3\xe3\x3e\xdd\x2f\x2f\x71\x5e\x84\x84\x97\x13\x53\x53\xf5\xa6\xd1\xd1\x68\xb9\x00\x00\x00\x00\xed\xed\x2c\xc1\x20\x20\x60\x40\xfc\xfc\x1f\xe3\xb1\xb1\xc8\x79\x5b\x5b\xed\xb6\x6a\x6a\xbe\xd4\xcb\xcb\x46\x8d\xbe\xbe\xd9\x67\x39\x39\x4b\x72\x4a\x4a\xde\x94\x4c\x4c\xd4\x98\x58\x58\xe8\xb0\xcf\xcf\x4a\x85\xd0\xd0\x6b\xbb\xef\xef\x2a\xc5\xaa\xaa\xe5\x4f\xfb\xfb\x16\xed\x43\x43\xc5\x86\x4d\x4d\xd7\x9a\x33\x33\x55\x66\x85\x85\x94\x11\x45\x45\xcf\x8a\xf9\xf9\x10\xe9\x02\x02\x06\x04\x7f\x7f\x81\xfe\x50\x50\xf0\xa0\x3c\x3c\x44\x78\x9f\x9f\xba\x25\xa8\xa8\xe3\x4b\x51\x51\xf3\xa2\xa3\xa3\xfe\x5d\x40\x40\xc0\x80\x8f\x8f\x8a\x05\x92\x92\xad\x3f\x9d\x9d\xbc\x21\x38\x38\x48\x70\xf5\xf5\x04\xf1\xbc\xbc\xdf\x63\xb6\xb6\xc1\x77\xda\xda\x75\xaf\x21\x21\x63\x42\x10\x10\x30\x20\xff\xff\x1a\xe5\xf3\xf3\x0e\xfd\xd2\xd2\x6d\xbf\xcd\xcd\x4c\x81\x0c\x0c\x14\x18\x13\x13\x35\x26\xec\xec\x2f\xc3\x5f\x5f\xe1\xbe\x97\x97\xa2\x35\x44\x44\xcc\x88\x17\x17\x39\x2e\xc4\xc4\x57\x93\xa7\xa7\xf2\x55\x7e\x7e\x82\xfc\x3d\x3d\x47\x7a\x64\x64\xac\xc8\x5d\x5d\xe7\xba\x19\x19\x2b\x32\x73\x73\x95\xe6\x60\x60\xa0\xc0\x81\x81\x98\x19\x4f\x4f\xd1\x9e\xdc\xdc\x7f\xa3\x22\x22\x66\x44\x2a\x2a\x7e\x54\x90\x90\xab\x3b\x88\x88\x83\x0b\x46\x46\xca\x8c\xee\xee\x29\xc7\xb8\xb8\xd3\x6b\x14\x14\x3c\x28\xde\xde\x79\xa7\x5e\x5e\xe2\xbc\x0b\x0b\x1d\x16\xdb\xdb\x76\xad\xe0\xe0\x3b\xdb\x32\x32\x56\x64\x3a\x3a\x4e\x74\x0a\x0a\x1e\x14\x49\x49\xdb\x92\x06\x06\x0a\x0c\x24\x24\x6c\x48\x5c\x5c\xe4\xb8\xc2\xc2\x5d\x9f\xd3\xd3\x6e\xbd\xac\xac\xef\x43\x62\x62\xa6\xc4\x91\x91\xa8\x39\x95\x95\xa4\x31\xe4\xe4\x37\xd3\x79\x79\x8b\xf2\xe7\xe7\x32\xd5\xc8\xc8\x43\x8b\x37\x37\x59\x6e\x6d\x6d\xb7\xda\x8d\x8d\x8c\x01\xd5\xd5\x64\xb1\x4e\x4e\xd2\x9c\xa9\xa9\xe0\x49\x6c\x6c\xb4\xd8\x56\x56\xfa\xac\xf4\xf4\x07\xf3\xea\xea\x25\xcf\x65\x65\xaf\xca\x7a\x7a\x8e\xf4\xae\xae\xe9\x47\x08\x08\x18\x10\xba\xba\xd5\x6f\x78\x78\x88\xf0\x25\x25\x6f\x4a\x2e\x2e\x72\x5c\x1c\x1c\x24\x38\xa6\xa6\xf1\x57\xb4\xb4\xc7\x73\xc6\xc6\x51\x97\xe8\xe8\x23\xcb\xdd\xdd\x7c\xa1\x74\x74\x9c\xe8\x1f\x1f\x21\x3e\x4b\x4b\xdd\x96\xbd\xbd\xdc\x61\x8b\x8b\x86\x0d\x8a\x8a\x85\x0f\x70\x70\x90\xe0\x3e\x3e\x42\x7c\xb5\xb5\xc4\x71\x66\x66\xaa\xcc\x48\x48\xd8\x90\x03\x03\x05\x06\xf6\xf6\x01\xf7\x0e\x0e\x12\x1c\x61\x61\xa3\xc2\x35\x35\x5f\x6a\x57\x57\xf9\xae\xb9\xb9\xd0\x69\x86\x86\x91\x17\xc1\xc1\x58\x99\x1d\x1d\x27\x3a\x9e\x9e\xb9\x27\xe1\xe1\x38\xd9\xf8\xf8\x13\xeb\x98\x98\xb3\x2b\x11\x11\x33\x22\x69\x69\xbb\xd2\xd9\xd9\x70\xa9\x8e\x8e\x89\x07\x94\x94\xa7\x33\x9b\x9b\xb6\x2d\x1e\x1e\x22\x3c\x87\x87\x92\x15\xe9\xe9\x20\xc9\xce\xce\x49\x87\x55\x55\xff\xaa\x28\x28\x78\x50\xdf\xdf\x7a\xa5\x8c\x8c\x8f\x03\xa1\xa1\xf8\x59\x89\x89\x80\x09\x0d\x0d\x17\x1a\xbf\xbf\xda\x65\xe6\xe6\x31\xd7\x42\x42\xc6\x84\x68\x68\xb8\xd0\x41\x41\xc3\x82\x99\x99\xb0\x29\x2d\x2d\x77\x5a\x0f\x0f\x11\x1e\xb0\xb0\xcb\x7b\x54\x54\xfc\xa8\xbb\xbb\xd6\x6d\x16\x16\x3a\x2c");

  // Transformations for decryption
  static T5 = rawToIntArray("\x51\xf4\xa7\x50\x7e\x41\x65\x53\x1a\x17\xa4\xc3\x3a\x27\x5e\x96\x3b\xab\x6b\xcb\x1f\x9d\x45\xf1\xac\xfa\x58\xab\x4b\xe3\x03\x93\x20\x30\xfa\x55\xad\x76\x6d\xf6\x88\xcc\x76\x91\xf5\x02\x4c\x25\x4f\xe5\xd7\xfc\xc5\x2a\xcb\xd7\x26\x35\x44\x80\xb5\x62\xa3\x8f\xde\xb1\x5a\x49\x25\xba\x1b\x67\x45\xea\x0e\x98\x5d\xfe\xc0\xe1\xc3\x2f\x75\x02\x81\x4c\xf0\x12\x8d\x46\x97\xa3\x6b\xd3\xf9\xc6\x03\x8f\x5f\xe7\x15\x92\x9c\x95\xbf\x6d\x7a\xeb\x95\x52\x59\xda\xd4\xbe\x83\x2d\x58\x74\x21\xd3\x49\xe0\x69\x29\x8e\xc9\xc8\x44\x75\xc2\x89\x6a\xf4\x8e\x79\x78\x99\x58\x3e\x6b\x27\xb9\x71\xdd\xbe\xe1\x4f\xb6\xf0\x88\xad\x17\xc9\x20\xac\x66\x7d\xce\x3a\xb4\x63\xdf\x4a\x18\xe5\x1a\x31\x82\x97\x51\x33\x60\x62\x53\x7f\x45\xb1\x64\x77\xe0\xbb\x6b\xae\x84\xfe\x81\xa0\x1c\xf9\x08\x2b\x94\x70\x48\x68\x58\x8f\x45\xfd\x19\x94\xde\x6c\x87\x52\x7b\xf8\xb7\xab\x73\xd3\x23\x72\x4b\x02\xe2\xe3\x1f\x8f\x57\x66\x55\xab\x2a\xb2\xeb\x28\x07\x2f\xb5\xc2\x03\x86\xc5\x7b\x9a\xd3\x37\x08\xa5\x30\x28\x87\xf2\x23\xbf\xa5\xb2\x02\x03\x6a\xba\xed\x16\x82\x5c\x8a\xcf\x1c\x2b\xa7\x79\xb4\x92\xf3\x07\xf2\xf0\x4e\x69\xe2\xa1\x65\xda\xf4\xcd\x06\x05\xbe\xd5\xd1\x34\x62\x1f\xc4\xa6\xfe\x8a\x34\x2e\x53\x9d\xa2\xf3\x55\xa0\x05\x8a\xe1\x32\xa4\xf6\xeb\x75\x0b\x83\xec\x39\x40\x60\xef\xaa\x5e\x71\x9f\x06\xbd\x6e\x10\x51\x3e\x21\x8a\xf9\x96\xdd\x06\x3d\xdd\x3e\x05\xae\x4d\xe6\xbd\x46\x91\x54\x8d\xb5\x71\xc4\x5d\x05\x04\x06\xd4\x6f\x60\x50\x15\xff\x19\x98\xfb\x24\xd6\xbd\xe9\x97\x89\x40\x43\xcc\x67\xd9\x9e\x77\xb0\xe8\x42\xbd\x07\x89\x8b\x88\xe7\x19\x5b\x38\x79\xc8\xee\xdb\xa1\x7c\x0a\x47\x7c\x42\x0f\xe9\xf8\x84\x1e\xc9\x00\x00\x00\x00\x09\x80\x86\x83\x32\x2b\xed\x48\x1e\x11\x70\xac\x6c\x5a\x72\x4e\xfd\x0e\xff\xfb\x0f\x85\x38\x56\x3d\xae\xd5\x1e\x36\x2d\x39\x27\x0a\x0f\xd9\x64\x68\x5c\xa6\x21\x9b\x5b\x54\xd1\x24\x36\x2e\x3a\x0c\x0a\x67\xb1\x93\x57\xe7\x0f\xb4\xee\x96\xd2\x1b\x9b\x91\x9e\x80\xc0\xc5\x4f\x61\xdc\x20\xa2\x5a\x77\x4b\x69\x1c\x12\x1a\x16\xe2\x93\xba\x0a\xc0\xa0\x2a\xe5\x3c\x22\xe0\x43\x12\x1b\x17\x1d\x0e\x09\x0d\x0b\xf2\x8b\xc7\xad\x2d\xb6\xa8\xb9\x14\x1e\xa9\xc8\x57\xf1\x19\x85\xaf\x75\x07\x4c\xee\x99\xdd\xbb\xa3\x7f\x60\xfd\xf7\x01\x26\x9f\x5c\x72\xf5\xbc\x44\x66\x3b\xc5\x5b\xfb\x7e\x34\x8b\x43\x29\x76\xcb\x23\xc6\xdc\xb6\xed\xfc\x68\xb8\xe4\xf1\x63\xd7\x31\xdc\xca\x42\x63\x85\x10\x13\x97\x22\x40\x84\xc6\x11\x20\x85\x4a\x24\x7d\xd2\xbb\x3d\xf8\xae\xf9\x32\x11\xc7\x29\xa1\x6d\x1d\x9e\x2f\x4b\xdc\xb2\x30\xf3\x0d\x86\x52\xec\x77\xc1\xe3\xd0\x2b\xb3\x16\x6c\xa9\x70\xb9\x99\x11\x94\x48\xfa\x47\xe9\x64\x22\xa8\xfc\x8c\xc4\xa0\xf0\x3f\x1a\x56\x7d\x2c\xd8\x22\x33\x90\xef\x87\x49\x4e\xc7\xd9\x38\xd1\xc1\x8c\xca\xa2\xfe\x98\xd4\x0b\x36\xa6\xf5\x81\xcf\xa5\x7a\xde\x28\xda\xb7\x8e\x26\x3f\xad\xbf\xa4\x2c\x3a\x9d\xe4\x50\x78\x92\x0d\x6a\x5f\xcc\x9b\x54\x7e\x46\x62\xf6\x8d\x13\xc2\x90\xd8\xb8\xe8\x2e\x39\xf7\x5e\x82\xc3\xaf\xf5\x9f\x5d\x80\xbe\x69\xd0\x93\x7c\x6f\xd5\x2d\xa9\xcf\x25\x12\xb3\xc8\xac\x99\x3b\x10\x18\x7d\xa7\xe8\x9c\x63\x6e\xdb\x3b\xbb\x7b\xcd\x26\x78\x09\x6e\x59\x18\xf4\xec\x9a\xb7\x01\x83\x4f\x9a\xa8\xe6\x95\x6e\x65\xaa\xff\xe6\x7e\x21\xbc\xcf\x08\xef\x15\xe8\xe6\xba\xe7\x9b\xd9\x4a\x6f\x36\xce\xea\x9f\x09\xd4\x29\xb0\x7c\xd6\x31\xa4\xb2\xaf\x2a\x3f\x23\x31\xc6\xa5\x94\x30\x35\xa2\x66\xc0\x74\x4e\xbc\x37\xfc\x82\xca\xa6\xe0\x90\xd0\xb0\x33\xa7\xd8\x15\xf1\x04\x98\x4a\x41\xec\xda\xf7\x7f\xcd\x50\x0e\x17\x91\xf6\x2f\x76\x4d\xd6\x8d\x43\xef\xb0\x4d\xcc\xaa\x4d\x54\xe4\x96\x04\xdf\x9e\xd1\xb5\xe3\x4c\x6a\x88\x1b\xc1\x2c\x1f\xb8\x46\x65\x51\x7f\x9d\x5e\xea\x04\x01\x8c\x35\x5d\xfa\x87\x74\x73\xfb\x0b\x41\x2e\xb3\x67\x1d\x5a\x92\xdb\xd2\x52\xe9\x10\x56\x33\x6d\xd6\x47\x13\x9a\xd7\x61\x8c\x37\xa1\x0c\x7a\x59\xf8\x14\x8e\xeb\x13\x3c\x89\xce\xa9\x27\xee\xb7\x61\xc9\x35\xe1\x1c\xe5\xed\x7a\x47\xb1\x3c\x9c\xd2\xdf\x59\x55\xf2\x73\x3f\x18\x14\xce\x79\x73\xc7\x37\xbf\x53\xf7\xcd\xea\x5f\xfd\xaa\x5b\xdf\x3d\x6f\x14\x78\x44\xdb\x86\xca\xaf\xf3\x81\xb9\x68\xc4\x3e\x38\x24\x34\x2c\xc2\xa3\x40\x5f\x16\x1d\xc3\x72\xbc\xe2\x25\x0c\x28\x3c\x49\x8b\xff\x0d\x95\x41\x39\xa8\x01\x71\x08\x0c\xb3\xde\xd8\xb4\xe4\x9c\x64\x56\xc1\x90\x7b\xcb\x84\x61\xd5\x32\xb6\x70\x48\x6c\x5c\x74\xd0\xb8\x57\x42");
  static T6 = rawToIntArray("\x50\x51\xf4\xa7\x53\x7e\x41\x65\xc3\x1a\x17\xa4\x96\x3a\x27\x5e\xcb\x3b\xab\x6b\xf1\x1f\x9d\x45\xab\xac\xfa\x58\x93\x4b\xe3\x03\x55\x20\x30\xfa\xf6\xad\x76\x6d\x91\x88\xcc\x76\x25\xf5\x02\x4c\xfc\x4f\xe5\xd7\xd7\xc5\x2a\xcb\x80\x26\x35\x44\x8f\xb5\x62\xa3\x49\xde\xb1\x5a\x67\x25\xba\x1b\x98\x45\xea\x0e\xe1\x5d\xfe\xc0\x02\xc3\x2f\x75\x12\x81\x4c\xf0\xa3\x8d\x46\x97\xc6\x6b\xd3\xf9\xe7\x03\x8f\x5f\x95\x15\x92\x9c\xeb\xbf\x6d\x7a\xda\x95\x52\x59\x2d\xd4\xbe\x83\xd3\x58\x74\x21\x29\x49\xe0\x69\x44\x8e\xc9\xc8\x6a\x75\xc2\x89\x78\xf4\x8e\x79\x6b\x99\x58\x3e\xdd\x27\xb9\x71\xb6\xbe\xe1\x4f\x17\xf0\x88\xad\x66\xc9\x20\xac\xb4\x7d\xce\x3a\x18\x63\xdf\x4a\x82\xe5\x1a\x31\x60\x97\x51\x33\x45\x62\x53\x7f\xe0\xb1\x64\x77\x84\xbb\x6b\xae\x1c\xfe\x81\xa0\x94\xf9\x08\x2b\x58\x70\x48\x68\x19\x8f\x45\xfd\x87\x94\xde\x6c\xb7\x52\x7b\xf8\x23\xab\x73\xd3\xe2\x72\x4b\x02\x57\xe3\x1f\x8f\x2a\x66\x55\xab\x07\xb2\xeb\x28\x03\x2f\xb5\xc2\x9a\x86\xc5\x7b\xa5\xd3\x37\x08\xf2\x30\x28\x87\xb2\x23\xbf\xa5\xba\x02\x03\x6a\x5c\xed\x16\x82\x2b\x8a\xcf\x1c\x92\xa7\x79\xb4\xf0\xf3\x07\xf2\xa1\x4e\x69\xe2\xcd\x65\xda\xf4\xd5\x06\x05\xbe\x1f\xd1\x34\x62\x8a\xc4\xa6\xfe\x9d\x34\x2e\x53\xa0\xa2\xf3\x55\x32\x05\x8a\xe1\x75\xa4\xf6\xeb\x39\x0b\x83\xec\xaa\x40\x60\xef\x06\x5e\x71\x9f\x51\xbd\x6e\x10\xf9\x3e\x21\x8a\x3d\x96\xdd\x06\xae\xdd\x3e\x05\x46\x4d\xe6\xbd\xb5\x91\x54\x8d\x05\x71\xc4\x5d\x6f\x04\x06\xd4\xff\x60\x50\x15\x24\x19\x98\xfb\x97\xd6\xbd\xe9\xcc\x89\x40\x43\x77\x67\xd9\x9e\xbd\xb0\xe8\x42\x88\x07\x89\x8b\x38\xe7\x19\x5b\xdb\x79\xc8\xee\x47\xa1\x7c\x0a\xe9\x7c\x42\x0f\xc9\xf8\x84\x1e\x00\x00\x00\x00\x83\x09\x80\x86\x48\x32\x2b\xed\xac\x1e\x11\x70\x4e\x6c\x5a\x72\xfb\xfd\x0e\xff\x56\x0f\x85\x38\x1e\x3d\xae\xd5\x27\x36\x2d\x39\x64\x0a\x0f\xd9\x21\x68\x5c\xa6\xd1\x9b\x5b\x54\x3a\x24\x36\x2e\xb1\x0c\x0a\x67\x0f\x93\x57\xe7\xd2\xb4\xee\x96\x9e\x1b\x9b\x91\x4f\x80\xc0\xc5\xa2\x61\xdc\x20\x69\x5a\x77\x4b\x16\x1c\x12\x1a\x0a\xe2\x93\xba\xe5\xc0\xa0\x2a\x43\x3c\x22\xe0\x1d\x12\x1b\x17\x0b\x0e\x09\x0d\xad\xf2\x8b\xc7\xb9\x2d\xb6\xa8\xc8\x14\x1e\xa9\x85\x57\xf1\x19\x4c\xaf\x75\x07\xbb\xee\x99\xdd\xfd\xa3\x7f\x60\x9f\xf7\x01\x26\xbc\x5c\x72\xf5\xc5\x44\x66\x3b\x34\x5b\xfb\x7e\x76\x8b\x43\x29\xdc\xcb\x23\xc6\x68\xb6\xed\xfc\x63\xb8\xe4\xf1\xca\xd7\x31\xdc\x10\x42\x63\x85\x40\x13\x97\x22\x20\x84\xc6\x11\x7d\x85\x4a\x24\xf8\xd2\xbb\x3d\x11\xae\xf9\x32\x6d\xc7\x29\xa1\x4b\x1d\x9e\x2f\xf3\xdc\xb2\x30\xec\x0d\x86\x52\xd0\x77\xc1\xe3\x6c\x2b\xb3\x16\x99\xa9\x70\xb9\xfa\x11\x94\x48\x22\x47\xe9\x64\xc4\xa8\xfc\x8c\x1a\xa0\xf0\x3f\xd8\x56\x7d\x2c\xef\x22\x33\x90\xc7\x87\x49\x4e\xc1\xd9\x38\xd1\xfe\x8c\xca\xa2\x36\x98\xd4\x0b\xcf\xa6\xf5\x81\x28\xa5\x7a\xde\x26\xda\xb7\x8e\xa4\x3f\xad\xbf\xe4\x2c\x3a\x9d\x0d\x50\x78\x92\x9b\x6a\x5f\xcc\x62\x54\x7e\x46\xc2\xf6\x8d\x13\xe8\x90\xd8\xb8\x5e\x2e\x39\xf7\xf5\x82\xc3\xaf\xbe\x9f\x5d\x80\x7c\x69\xd0\x93\xa9\x6f\xd5\x2d\xb3\xcf\x25\x12\x3b\xc8\xac\x99\xa7\x10\x18\x7d\x6e\xe8\x9c\x63\x7b\xdb\x3b\xbb\x09\xcd\x26\x78\xf4\x6e\x59\x18\x01\xec\x9a\xb7\xa8\x83\x4f\x9a\x65\xe6\x95\x6e\x7e\xaa\xff\xe6\x08\x21\xbc\xcf\xe6\xef\x15\xe8\xd9\xba\xe7\x9b\xce\x4a\x6f\x36\xd4\xea\x9f\x09\xd6\x29\xb0\x7c\xaf\x31\xa4\xb2\x31\x2a\x3f\x23\x30\xc6\xa5\x94\xc0\x35\xa2\x66\x37\x74\x4e\xbc\xa6\xfc\x82\xca\xb0\xe0\x90\xd0\x15\x33\xa7\xd8\x4a\xf1\x04\x98\xf7\x41\xec\xda\x0e\x7f\xcd\x50\x2f\x17\x91\xf6\x8d\x76\x4d\xd6\x4d\x43\xef\xb0\x54\xcc\xaa\x4d\xdf\xe4\x96\x04\xe3\x9e\xd1\xb5\x1b\x4c\x6a\x88\xb8\xc1\x2c\x1f\x7f\x46\x65\x51\x04\x9d\x5e\xea\x5d\x01\x8c\x35\x73\xfa\x87\x74\x2e\xfb\x0b\x41\x5a\xb3\x67\x1d\x52\x92\xdb\xd2\x33\xe9\x10\x56\x13\x6d\xd6\x47\x8c\x9a\xd7\x61\x7a\x37\xa1\x0c\x8e\x59\xf8\x14\x89\xeb\x13\x3c\xee\xce\xa9\x27\x35\xb7\x61\xc9\xed\xe1\x1c\xe5\x3c\x7a\x47\xb1\x59\x9c\xd2\xdf\x3f\x55\xf2\x73\x79\x18\x14\xce\xbf\x73\xc7\x37\xea\x53\xf7\xcd\x5b\x5f\xfd\xaa\x14\xdf\x3d\x6f\x86\x78\x44\xdb\x81\xca\xaf\xf3\x3e\xb9\x68\xc4\x2c\x38\x24\x34\x5f\xc2\xa3\x40\x72\x16\x1d\xc3\x0c\xbc\xe2\x25\x8b\x28\x3c\x49\x41\xff\x0d\x95\x71\x39\xa8\x01\xde\x08\x0c\xb3\x9c\xd8\xb4\xe4\x90\x64\x56\xc1\x61\x7b\xcb\x84\x70\xd5\x32\xb6\x74\x48\x6c\x5c\x42\xd0\xb8\x57");
  static T7 = rawToIntArray("\xa7\x50\x51\xf4\x65\x53\x7e\x41\xa4\xc3\x1a\x17\x5e\x96\x3a\x27\x6b\xcb\x3b\xab\x45\xf1\x1f\x9d\x58\xab\xac\xfa\x03\x93\x4b\xe3\xfa\x55\x20\x30\x6d\xf6\xad\x76\x76\x91\x88\xcc\x4c\x25\xf5\x02\xd7\xfc\x4f\xe5\xcb\xd7\xc5\x2a\x44\x80\x26\x35\xa3\x8f\xb5\x62\x5a\x49\xde\xb1\x1b\x67\x25\xba\x0e\x98\x45\xea\xc0\xe1\x5d\xfe\x75\x02\xc3\x2f\xf0\x12\x81\x4c\x97\xa3\x8d\x46\xf9\xc6\x6b\xd3\x5f\xe7\x03\x8f\x9c\x95\x15\x92\x7a\xeb\xbf\x6d\x59\xda\x95\x52\x83\x2d\xd4\xbe\x21\xd3\x58\x74\x69\x29\x49\xe0\xc8\x44\x8e\xc9\x89\x6a\x75\xc2\x79\x78\xf4\x8e\x3e\x6b\x99\x58\x71\xdd\x27\xb9\x4f\xb6\xbe\xe1\xad\x17\xf0\x88\xac\x66\xc9\x20\x3a\xb4\x7d\xce\x4a\x18\x63\xdf\x31\x82\xe5\x1a\x33\x60\x97\x51\x7f\x45\x62\x53\x77\xe0\xb1\x64\xae\x84\xbb\x6b\xa0\x1c\xfe\x81\x2b\x94\xf9\x08\x68\x58\x70\x48\xfd\x19\x8f\x45\x6c\x87\x94\xde\xf8\xb7\x52\x7b\xd3\x23\xab\x73\x02\xe2\x72\x4b\x8f\x57\xe3\x1f\xab\x2a\x66\x55\x28\x07\xb2\xeb\xc2\x03\x2f\xb5\x7b\x9a\x86\xc5\x08\xa5\xd3\x37\x87\xf2\x30\x28\xa5\xb2\x23\xbf\x6a\xba\x02\x03\x82\x5c\xed\x16\x1c\x2b\x8a\xcf\xb4\x92\xa7\x79\xf2\xf0\xf3\x07\xe2\xa1\x4e\x69\xf4\xcd\x65\xda\xbe\xd5\x06\x05\x62\x1f\xd1\x34\xfe\x8a\xc4\xa6\x53\x9d\x34\x2e\x55\xa0\xa2\xf3\xe1\x32\x05\x8a\xeb\x75\xa4\xf6\xec\x39\x0b\x83\xef\xaa\x40\x60\x9f\x06\x5e\x71\x10\x51\xbd\x6e\x8a\xf9\x3e\x21\x06\x3d\x96\xdd\x05\xae\xdd\x3e\xbd\x46\x4d\xe6\x8d\xb5\x91\x54\x5d\x05\x71\xc4\xd4\x6f\x04\x06\x15\xff\x60\x50\xfb\x24\x19\x98\xe9\x97\xd6\xbd\x43\xcc\x89\x40\x9e\x77\x67\xd9\x42\xbd\xb0\xe8\x8b\x88\x07\x89\x5b\x38\xe7\x19\xee\xdb\x79\xc8\x0a\x47\xa1\x7c\x0f\xe9\x7c\x42\x1e\xc9\xf8\x84\x00\x00\x00\x00\x86\x83\x09\x80\xed\x48\x32\x2b\x70\xac\x1e\x11\x72\x4e\x6c\x5a\xff\xfb\xfd\x0e\x38\x56\x0f\x85\xd5\x1e\x3d\xae\x39\x27\x36\x2d\xd9\x64\x0a\x0f\xa6\x21\x68\x5c\x54\xd1\x9b\x5b\x2e\x3a\x24\x36\x67\xb1\x0c\x0a\xe7\x0f\x93\x57\x96\xd2\xb4\xee\x91\x9e\x1b\x9b\xc5\x4f\x80\xc0\x20\xa2\x61\xdc\x4b\x69\x5a\x77\x1a\x16\x1c\x12\xba\x0a\xe2\x93\x2a\xe5\xc0\xa0\xe0\x43\x3c\x22\x17\x1d\x12\x1b\x0d\x0b\x0e\x09\xc7\xad\xf2\x8b\xa8\xb9\x2d\xb6\xa9\xc8\x14\x1e\x19\x85\x57\xf1\x07\x4c\xaf\x75\xdd\xbb\xee\x99\x60\xfd\xa3\x7f\x26\x9f\xf7\x01\xf5\xbc\x5c\x72\x3b\xc5\x44\x66\x7e\x34\x5b\xfb\x29\x76\x8b\x43\xc6\xdc\xcb\x23\xfc\x68\xb6\xed\xf1\x63\xb8\xe4\xdc\xca\xd7\x31\x85\x10\x42\x63\x22\x40\x13\x97\x11\x20\x84\xc6\x24\x7d\x85\x4a\x3d\xf8\xd2\xbb\x32\x11\xae\xf9\xa1\x6d\xc7\x29\x2f\x4b\x1d\x9e\x30\xf3\xdc\xb2\x52\xec\x0d\x86\xe3\xd0\x77\xc1\x16\x6c\x2b\xb3\xb9\x99\xa9\x70\x48\xfa\x11\x94\x64\x22\x47\xe9\x8c\xc4\xa8\xfc\x3f\x1a\xa0\xf0\x2c\xd8\x56\x7d\x90\xef\x22\x33\x4e\xc7\x87\x49\xd1\xc1\xd9\x38\xa2\xfe\x8c\xca\x0b\x36\x98\xd4\x81\xcf\xa6\xf5\xde\x28\xa5\x7a\x8e\x26\xda\xb7\xbf\xa4\x3f\xad\x9d\xe4\x2c\x3a\x92\x0d\x50\x78\xcc\x9b\x6a\x5f\x46\x62\x54\x7e\x13\xc2\xf6\x8d\xb8\xe8\x90\xd8\xf7\x5e\x2e\x39\xaf\xf5\x82\xc3\x80\xbe\x9f\x5d\x93\x7c\x69\xd0\x2d\xa9\x6f\xd5\x12\xb3\xcf\x25\x99\x3b\xc8\xac\x7d\xa7\x10\x18\x63\x6e\xe8\x9c\xbb\x7b\xdb\x3b\x78\x09\xcd\x26\x18\xf4\x6e\x59\xb7\x01\xec\x9a\x9a\xa8\x83\x4f\x6e\x65\xe6\x95\xe6\x7e\xaa\xff\xcf\x08\x21\xbc\xe8\xe6\xef\x15\x9b\xd9\xba\xe7\x36\xce\x4a\x6f\x09\xd4\xea\x9f\x7c\xd6\x29\xb0\xb2\xaf\x31\xa4\x23\x31\x2a\x3f\x94\x30\xc6\xa5\x66\xc0\x35\xa2\xbc\x37\x74\x4e\xca\xa6\xfc\x82\xd0\xb0\xe0\x90\xd8\x15\x33\xa7\x98\x4a\xf1\x04\xda\xf7\x41\xec\x50\x0e\x7f\xcd\xf6\x2f\x17\x91\xd6\x8d\x76\x4d\xb0\x4d\x43\xef\x4d\x54\xcc\xaa\x04\xdf\xe4\x96\xb5\xe3\x9e\xd1\x88\x1b\x4c\x6a\x1f\xb8\xc1\x2c\x51\x7f\x46\x65\xea\x04\x9d\x5e\x35\x5d\x01\x8c\x74\x73\xfa\x87\x41\x2e\xfb\x0b\x1d\x5a\xb3\x67\xd2\x52\x92\xdb\x56\x33\xe9\x10\x47\x13\x6d\xd6\x61\x8c\x9a\xd7\x0c\x7a\x37\xa1\x14\x8e\x59\xf8\x3c\x89\xeb\x13\x27\xee\xce\xa9\xc9\x35\xb7\x61\xe5\xed\xe1\x1c\xb1\x3c\x7a\x47\xdf\x59\x9c\xd2\x73\x3f\x55\xf2\xce\x79\x18\x14\x37\xbf\x73\xc7\xcd\xea\x53\xf7\xaa\x5b\x5f\xfd\x6f\x14\xdf\x3d\xdb\x86\x78\x44\xf3\x81\xca\xaf\xc4\x3e\xb9\x68\x34\x2c\x38\x24\x40\x5f\xc2\xa3\xc3\x72\x16\x1d\x25\x0c\xbc\xe2\x49\x8b\x28\x3c\x95\x41\xff\x0d\x01\x71\x39\xa8\xb3\xde\x08\x0c\xe4\x9c\xd8\xb4\xc1\x90\x64\x56\x84\x61\x7b\xcb\xb6\x70\xd5\x32\x5c\x74\x48\x6c\x57\x42\xd0\xb8");
  static T8 = rawToIntArray("\xf4\xa7\x50\x51\x41\x65\x53\x7e\x17\xa4\xc3\x1a\x27\x5e\x96\x3a\xab\x6b\xcb\x3b\x9d\x45\xf1\x1f\xfa\x58\xab\xac\xe3\x03\x93\x4b\x30\xfa\x55\x20\x76\x6d\xf6\xad\xcc\x76\x91\x88\x02\x4c\x25\xf5\xe5\xd7\xfc\x4f\x2a\xcb\xd7\xc5\x35\x44\x80\x26\x62\xa3\x8f\xb5\xb1\x5a\x49\xde\xba\x1b\x67\x25\xea\x0e\x98\x45\xfe\xc0\xe1\x5d\x2f\x75\x02\xc3\x4c\xf0\x12\x81\x46\x97\xa3\x8d\xd3\xf9\xc6\x6b\x8f\x5f\xe7\x03\x92\x9c\x95\x15\x6d\x7a\xeb\xbf\x52\x59\xda\x95\xbe\x83\x2d\xd4\x74\x21\xd3\x58\xe0\x69\x29\x49\xc9\xc8\x44\x8e\xc2\x89\x6a\x75\x8e\x79\x78\xf4\x58\x3e\x6b\x99\xb9\x71\xdd\x27\xe1\x4f\xb6\xbe\x88\xad\x17\xf0\x20\xac\x66\xc9\xce\x3a\xb4\x7d\xdf\x4a\x18\x63\x1a\x31\x82\xe5\x51\x33\x60\x97\x53\x7f\x45\x62\x64\x77\xe0\xb1\x6b\xae\x84\xbb\x81\xa0\x1c\xfe\x08\x2b\x94\xf9\x48\x68\x58\x70\x45\xfd\x19\x8f\xde\x6c\x87\x94\x7b\xf8\xb7\x52\x73\xd3\x23\xab\x4b\x02\xe2\x72\x1f\x8f\x57\xe3\x55\xab\x2a\x66\xeb\x28\x07\xb2\xb5\xc2\x03\x2f\xc5\x7b\x9a\x86\x37\x08\xa5\xd3\x28\x87\xf2\x30\xbf\xa5\xb2\x23\x03\x6a\xba\x02\x16\x82\x5c\xed\xcf\x1c\x2b\x8a\x79\xb4\x92\xa7\x07\xf2\xf0\xf3\x69\xe2\xa1\x4e\xda\xf4\xcd\x65\x05\xbe\xd5\x06\x34\x62\x1f\xd1\xa6\xfe\x8a\xc4\x2e\x53\x9d\x34\xf3\x55\xa0\xa2\x8a\xe1\x32\x05\xf6\xeb\x75\xa4\x83\xec\x39\x0b\x60\xef\xaa\x40\x71\x9f\x06\x5e\x6e\x10\x51\xbd\x21\x8a\xf9\x3e\xdd\x06\x3d\x96\x3e\x05\xae\xdd\xe6\xbd\x46\x4d\x54\x8d\xb5\x91\xc4\x5d\x05\x71\x06\xd4\x6f\x04\x50\x15\xff\x60\x98\xfb\x24\x19\xbd\xe9\x97\xd6\x40\x43\xcc\x89\xd9\x9e\x77\x67\xe8\x42\xbd\xb0\x89\x8b\x88\x07\x19\x5b\x38\xe7\xc8\xee\xdb\x79\x7c\x0a\x47\xa1\x42\x0f\xe9\x7c\x84\x1e\xc9\xf8\x00\x00\x00\x00\x80\x86\x83\x09\x2b\xed\x48\x32\x11\x70\xac\x1e\x5a\x72\x4e\x6c\x0e\xff\xfb\xfd\x85\x38\x56\x0f\xae\xd5\x1e\x3d\x2d\x39\x27\x36\x0f\xd9\x64\x0a\x5c\xa6\x21\x68\x5b\x54\xd1\x9b\x36\x2e\x3a\x24\x0a\x67\xb1\x0c\x57\xe7\x0f\x93\xee\x96\xd2\xb4\x9b\x91\x9e\x1b\xc0\xc5\x4f\x80\xdc\x20\xa2\x61\x77\x4b\x69\x5a\x12\x1a\x16\x1c\x93\xba\x0a\xe2\xa0\x2a\xe5\xc0\x22\xe0\x43\x3c\x1b\x17\x1d\x12\x09\x0d\x0b\x0e\x8b\xc7\xad\xf2\xb6\xa8\xb9\x2d\x1e\xa9\xc8\x14\xf1\x19\x85\x57\x75\x07\x4c\xaf\x99\xdd\xbb\xee\x7f\x60\xfd\xa3\x01\x26\x9f\xf7\x72\xf5\xbc\x5c\x66\x3b\xc5\x44\xfb\x7e\x34\x5b\x43\x29\x76\x8b\x23\xc6\xdc\xcb\xed\xfc\x68\xb6\xe4\xf1\x63\xb8\x31\xdc\xca\xd7\x63\x85\x10\x42\x97\x22\x40\x13\xc6\x11\x20\x84\x4a\x24\x7d\x85\xbb\x3d\xf8\xd2\xf9\x32\x11\xae\x29\xa1\x6d\xc7\x9e\x2f\x4b\x1d\xb2\x30\xf3\xdc\x86\x52\xec\x0d\xc1\xe3\xd0\x77\xb3\x16\x6c\x2b\x70\xb9\x99\xa9\x94\x48\xfa\x11\xe9\x64\x22\x47\xfc\x8c\xc4\xa8\xf0\x3f\x1a\xa0\x7d\x2c\xd8\x56\x33\x90\xef\x22\x49\x4e\xc7\x87\x38\xd1\xc1\xd9\xca\xa2\xfe\x8c\xd4\x0b\x36\x98\xf5\x81\xcf\xa6\x7a\xde\x28\xa5\xb7\x8e\x26\xda\xad\xbf\xa4\x3f\x3a\x9d\xe4\x2c\x78\x92\x0d\x50\x5f\xcc\x9b\x6a\x7e\x46\x62\x54\x8d\x13\xc2\xf6\xd8\xb8\xe8\x90\x39\xf7\x5e\x2e\xc3\xaf\xf5\x82\x5d\x80\xbe\x9f\xd0\x93\x7c\x69\xd5\x2d\xa9\x6f\x25\x12\xb3\xcf\xac\x99\x3b\xc8\x18\x7d\xa7\x10\x9c\x63\x6e\xe8\x3b\xbb\x7b\xdb\x26\x78\x09\xcd\x59\x18\xf4\x6e\x9a\xb7\x01\xec\x4f\x9a\xa8\x83\x95\x6e\x65\xe6\xff\xe6\x7e\xaa\xbc\xcf\x08\x21\x15\xe8\xe6\xef\xe7\x9b\xd9\xba\x6f\x36\xce\x4a\x9f\x09\xd4\xea\xb0\x7c\xd6\x29\xa4\xb2\xaf\x31\x3f\x23\x31\x2a\xa5\x94\x30\xc6\xa2\x66\xc0\x35\x4e\xbc\x37\x74\x82\xca\xa6\xfc\x90\xd0\xb0\xe0\xa7\xd8\x15\x33\x04\x98\x4a\xf1\xec\xda\xf7\x41\xcd\x50\x0e\x7f\x91\xf6\x2f\x17\x4d\xd6\x8d\x76\xef\xb0\x4d\x43\xaa\x4d\x54\xcc\x96\x04\xdf\xe4\xd1\xb5\xe3\x9e\x6a\x88\x1b\x4c\x2c\x1f\xb8\xc1\x65\x51\x7f\x46\x5e\xea\x04\x9d\x8c\x35\x5d\x01\x87\x74\x73\xfa\x0b\x41\x2e\xfb\x67\x1d\x5a\xb3\xdb\xd2\x52\x92\x10\x56\x33\xe9\xd6\x47\x13\x6d\xd7\x61\x8c\x9a\xa1\x0c\x7a\x37\xf8\x14\x8e\x59\x13\x3c\x89\xeb\xa9\x27\xee\xce\x61\xc9\x35\xb7\x1c\xe5\xed\xe1\x47\xb1\x3c\x7a\xd2\xdf\x59\x9c\xf2\x73\x3f\x55\x14\xce\x79\x18\xc7\x37\xbf\x73\xf7\xcd\xea\x53\xfd\xaa\x5b\x5f\x3d\x6f\x14\xdf\x44\xdb\x86\x78\xaf\xf3\x81\xca\x68\xc4\x3e\xb9\x24\x34\x2c\x38\xa3\x40\x5f\xc2\x1d\xc3\x72\x16\xe2\x25\x0c\xbc\x3c\x49\x8b\x28\x0d\x95\x41\xff\xa8\x01\x71\x39\x0c\xb3\xde\x08\xb4\xe4\x9c\xd8\x56\xc1\x90\x64\xcb\x84\x61\x7b\x32\xb6\x70\xd5\x6c\x5c\x74\x48\xb8\x57\x42\xd0");

  // Transformations for decryption key expansion
  static U1 = rawToIntArray("\x00\x00\x00\x00\x0e\x09\x0d\x0b\x1c\x12\x1a\x16\x12\x1b\x17\x1d\x38\x24\x34\x2c\x36\x2d\x39\x27\x24\x36\x2e\x3a\x2a\x3f\x23\x31\x70\x48\x68\x58\x7e\x41\x65\x53\x6c\x5a\x72\x4e\x62\x53\x7f\x45\x48\x6c\x5c\x74\x46\x65\x51\x7f\x54\x7e\x46\x62\x5a\x77\x4b\x69\xe0\x90\xd0\xb0\xee\x99\xdd\xbb\xfc\x82\xca\xa6\xf2\x8b\xc7\xad\xd8\xb4\xe4\x9c\xd6\xbd\xe9\x97\xc4\xa6\xfe\x8a\xca\xaf\xf3\x81\x90\xd8\xb8\xe8\x9e\xd1\xb5\xe3\x8c\xca\xa2\xfe\x82\xc3\xaf\xf5\xa8\xfc\x8c\xc4\xa6\xf5\x81\xcf\xb4\xee\x96\xd2\xba\xe7\x9b\xd9\xdb\x3b\xbb\x7b\xd5\x32\xb6\x70\xc7\x29\xa1\x6d\xc9\x20\xac\x66\xe3\x1f\x8f\x57\xed\x16\x82\x5c\xff\x0d\x95\x41\xf1\x04\x98\x4a\xab\x73\xd3\x23\xa5\x7a\xde\x28\xb7\x61\xc9\x35\xb9\x68\xc4\x3e\x93\x57\xe7\x0f\x9d\x5e\xea\x04\x8f\x45\xfd\x19\x81\x4c\xf0\x12\x3b\xab\x6b\xcb\x35\xa2\x66\xc0\x27\xb9\x71\xdd\x29\xb0\x7c\xd6\x03\x8f\x5f\xe7\x0d\x86\x52\xec\x1f\x9d\x45\xf1\x11\x94\x48\xfa\x4b\xe3\x03\x93\x45\xea\x0e\x98\x57\xf1\x19\x85\x59\xf8\x14\x8e\x73\xc7\x37\xbf\x7d\xce\x3a\xb4\x6f\xd5\x2d\xa9\x61\xdc\x20\xa2\xad\x76\x6d\xf6\xa3\x7f\x60\xfd\xb1\x64\x77\xe0\xbf\x6d\x7a\xeb\x95\x52\x59\xda\x9b\x5b\x54\xd1\x89\x40\x43\xcc\x87\x49\x4e\xc7\xdd\x3e\x05\xae\xd3\x37\x08\xa5\xc1\x2c\x1f\xb8\xcf\x25\x12\xb3\xe5\x1a\x31\x82\xeb\x13\x3c\x89\xf9\x08\x2b\x94\xf7\x01\x26\x9f\x4d\xe6\xbd\x46\x43\xef\xb0\x4d\x51\xf4\xa7\x50\x5f\xfd\xaa\x5b\x75\xc2\x89\x6a\x7b\xcb\x84\x61\x69\xd0\x93\x7c\x67\xd9\x9e\x77\x3d\xae\xd5\x1e\x33\xa7\xd8\x15\x21\xbc\xcf\x08\x2f\xb5\xc2\x03\x05\x8a\xe1\x32\x0b\x83\xec\x39\x19\x98\xfb\x24\x17\x91\xf6\x2f\x76\x4d\xd6\x8d\x78\x44\xdb\x86\x6a\x5f\xcc\x9b\x64\x56\xc1\x90\x4e\x69\xe2\xa1\x40\x60\xef\xaa\x52\x7b\xf8\xb7\x5c\x72\xf5\xbc\x06\x05\xbe\xd5\x08\x0c\xb3\xde\x1a\x17\xa4\xc3\x14\x1e\xa9\xc8\x3e\x21\x8a\xf9\x30\x28\x87\xf2\x22\x33\x90\xef\x2c\x3a\x9d\xe4\x96\xdd\x06\x3d\x98\xd4\x0b\x36\x8a\xcf\x1c\x2b\x84\xc6\x11\x20\xae\xf9\x32\x11\xa0\xf0\x3f\x1a\xb2\xeb\x28\x07\xbc\xe2\x25\x0c\xe6\x95\x6e\x65\xe8\x9c\x63\x6e\xfa\x87\x74\x73\xf4\x8e\x79\x78\xde\xb1\x5a\x49\xd0\xb8\x57\x42\xc2\xa3\x40\x5f\xcc\xaa\x4d\x54\x41\xec\xda\xf7\x4f\xe5\xd7\xfc\x5d\xfe\xc0\xe1\x53\xf7\xcd\xea\x79\xc8\xee\xdb\x77\xc1\xe3\xd0\x65\xda\xf4\xcd\x6b\xd3\xf9\xc6\x31\xa4\xb2\xaf\x3f\xad\xbf\xa4\x2d\xb6\xa8\xb9\x23\xbf\xa5\xb2\x09\x80\x86\x83\x07\x89\x8b\x88\x15\x92\x9c\x95\x1b\x9b\x91\x9e\xa1\x7c\x0a\x47\xaf\x75\x07\x4c\xbd\x6e\x10\x51\xb3\x67\x1d\x5a\x99\x58\x3e\x6b\x97\x51\x33\x60\x85\x4a\x24\x7d\x8b\x43\x29\x76\xd1\x34\x62\x1f\xdf\x3d\x6f\x14\xcd\x26\x78\x09\xc3\x2f\x75\x02\xe9\x10\x56\x33\xe7\x19\x5b\x38\xf5\x02\x4c\x25\xfb\x0b\x41\x2e\x9a\xd7\x61\x8c\x94\xde\x6c\x87\x86\xc5\x7b\x9a\x88\xcc\x76\x91\xa2\xf3\x55\xa0\xac\xfa\x58\xab\xbe\xe1\x4f\xb6\xb0\xe8\x42\xbd\xea\x9f\x09\xd4\xe4\x96\x04\xdf\xf6\x8d\x13\xc2\xf8\x84\x1e\xc9\xd2\xbb\x3d\xf8\xdc\xb2\x30\xf3\xce\xa9\x27\xee\xc0\xa0\x2a\xe5\x7a\x47\xb1\x3c\x74\x4e\xbc\x37\x66\x55\xab\x2a\x68\x5c\xa6\x21\x42\x63\x85\x10\x4c\x6a\x88\x1b\x5e\x71\x9f\x06\x50\x78\x92\x0d\x0a\x0f\xd9\x64\x04\x06\xd4\x6f\x16\x1d\xc3\x72\x18\x14\xce\x79\x32\x2b\xed\x48\x3c\x22\xe0\x43\x2e\x39\xf7\x5e\x20\x30\xfa\x55\xec\x9a\xb7\x01\xe2\x93\xba\x0a\xf0\x88\xad\x17\xfe\x81\xa0\x1c\xd4\xbe\x83\x2d\xda\xb7\x8e\x26\xc8\xac\x99\x3b\xc6\xa5\x94\x30\x9c\xd2\xdf\x59\x92\xdb\xd2\x52\x80\xc0\xc5\x4f\x8e\xc9\xc8\x44\xa4\xf6\xeb\x75\xaa\xff\xe6\x7e\xb8\xe4\xf1\x63\xb6\xed\xfc\x68\x0c\x0a\x67\xb1\x02\x03\x6a\xba\x10\x18\x7d\xa7\x1e\x11\x70\xac\x34\x2e\x53\x9d\x3a\x27\x5e\x96\x28\x3c\x49\x8b\x26\x35\x44\x80\x7c\x42\x0f\xe9\x72\x4b\x02\xe2\x60\x50\x15\xff\x6e\x59\x18\xf4\x44\x66\x3b\xc5\x4a\x6f\x36\xce\x58\x74\x21\xd3\x56\x7d\x2c\xd8\x37\xa1\x0c\x7a\x39\xa8\x01\x71\x2b\xb3\x16\x6c\x25\xba\x1b\x67\x0f\x85\x38\x56\x01\x8c\x35\x5d\x13\x97\x22\x40\x1d\x9e\x2f\x4b\x47\xe9\x64\x22\x49\xe0\x69\x29\x5b\xfb\x7e\x34\x55\xf2\x73\x3f\x7f\xcd\x50\x0e\x71\xc4\x5d\x05\x63\xdf\x4a\x18\x6d\xd6\x47\x13\xd7\x31\xdc\xca\xd9\x38\xd1\xc1\xcb\x23\xc6\xdc\xc5\x2a\xcb\xd7\xef\x15\xe8\xe6\xe1\x1c\xe5\xed\xf3\x07\xf2\xf0\xfd\x0e\xff\xfb\xa7\x79\xb4\x92\xa9\x70\xb9\x99\xbb\x6b\xae\x84\xb5\x62\xa3\x8f\x9f\x5d\x80\xbe\x91\x54\x8d\xb5\x83\x4f\x9a\xa8\x8d\x46\x97\xa3");
  static U2 = rawToIntArray("\x00\x00\x00\x00\x0b\x0e\x09\x0d\x16\x1c\x12\x1a\x1d\x12\x1b\x17\x2c\x38\x24\x34\x27\x36\x2d\x39\x3a\x24\x36\x2e\x31\x2a\x3f\x23\x58\x70\x48\x68\x53\x7e\x41\x65\x4e\x6c\x5a\x72\x45\x62\x53\x7f\x74\x48\x6c\x5c\x7f\x46\x65\x51\x62\x54\x7e\x46\x69\x5a\x77\x4b\xb0\xe0\x90\xd0\xbb\xee\x99\xdd\xa6\xfc\x82\xca\xad\xf2\x8b\xc7\x9c\xd8\xb4\xe4\x97\xd6\xbd\xe9\x8a\xc4\xa6\xfe\x81\xca\xaf\xf3\xe8\x90\xd8\xb8\xe3\x9e\xd1\xb5\xfe\x8c\xca\xa2\xf5\x82\xc3\xaf\xc4\xa8\xfc\x8c\xcf\xa6\xf5\x81\xd2\xb4\xee\x96\xd9\xba\xe7\x9b\x7b\xdb\x3b\xbb\x70\xd5\x32\xb6\x6d\xc7\x29\xa1\x66\xc9\x20\xac\x57\xe3\x1f\x8f\x5c\xed\x16\x82\x41\xff\x0d\x95\x4a\xf1\x04\x98\x23\xab\x73\xd3\x28\xa5\x7a\xde\x35\xb7\x61\xc9\x3e\xb9\x68\xc4\x0f\x93\x57\xe7\x04\x9d\x5e\xea\x19\x8f\x45\xfd\x12\x81\x4c\xf0\xcb\x3b\xab\x6b\xc0\x35\xa2\x66\xdd\x27\xb9\x71\xd6\x29\xb0\x7c\xe7\x03\x8f\x5f\xec\x0d\x86\x52\xf1\x1f\x9d\x45\xfa\x11\x94\x48\x93\x4b\xe3\x03\x98\x45\xea\x0e\x85\x57\xf1\x19\x8e\x59\xf8\x14\xbf\x73\xc7\x37\xb4\x7d\xce\x3a\xa9\x6f\xd5\x2d\xa2\x61\xdc\x20\xf6\xad\x76\x6d\xfd\xa3\x7f\x60\xe0\xb1\x64\x77\xeb\xbf\x6d\x7a\xda\x95\x52\x59\xd1\x9b\x5b\x54\xcc\x89\x40\x43\xc7\x87\x49\x4e\xae\xdd\x3e\x05\xa5\xd3\x37\x08\xb8\xc1\x2c\x1f\xb3\xcf\x25\x12\x82\xe5\x1a\x31\x89\xeb\x13\x3c\x94\xf9\x08\x2b\x9f\xf7\x01\x26\x46\x4d\xe6\xbd\x4d\x43\xef\xb0\x50\x51\xf4\xa7\x5b\x5f\xfd\xaa\x6a\x75\xc2\x89\x61\x7b\xcb\x84\x7c\x69\xd0\x93\x77\x67\xd9\x9e\x1e\x3d\xae\xd5\x15\x33\xa7\xd8\x08\x21\xbc\xcf\x03\x2f\xb5\xc2\x32\x05\x8a\xe1\x39\x0b\x83\xec\x24\x19\x98\xfb\x2f\x17\x91\xf6\x8d\x76\x4d\xd6\x86\x78\x44\xdb\x9b\x6a\x5f\xcc\x90\x64\x56\xc1\xa1\x4e\x69\xe2\xaa\x40\x60\xef\xb7\x52\x7b\xf8\xbc\x5c\x72\xf5\xd5\x06\x05\xbe\xde\x08\x0c\xb3\xc3\x1a\x17\xa4\xc8\x14\x1e\xa9\xf9\x3e\x21\x8a\xf2\x30\x28\x87\xef\x22\x33\x90\xe4\x2c\x3a\x9d\x3d\x96\xdd\x06\x36\x98\xd4\x0b\x2b\x8a\xcf\x1c\x20\x84\xc6\x11\x11\xae\xf9\x32\x1a\xa0\xf0\x3f\x07\xb2\xeb\x28\x0c\xbc\xe2\x25\x65\xe6\x95\x6e\x6e\xe8\x9c\x63\x73\xfa\x87\x74\x78\xf4\x8e\x79\x49\xde\xb1\x5a\x42\xd0\xb8\x57\x5f\xc2\xa3\x40\x54\xcc\xaa\x4d\xf7\x41\xec\xda\xfc\x4f\xe5\xd7\xe1\x5d\xfe\xc0\xea\x53\xf7\xcd\xdb\x79\xc8\xee\xd0\x77\xc1\xe3\xcd\x65\xda\xf4\xc6\x6b\xd3\xf9\xaf\x31\xa4\xb2\xa4\x3f\xad\xbf\xb9\x2d\xb6\xa8\xb2\x23\xbf\xa5\x83\x09\x80\x86\x88\x07\x89\x8b\x95\x15\x92\x9c\x9e\x1b\x9b\x91\x47\xa1\x7c\x0a\x4c\xaf\x75\x07\x51\xbd\x6e\x10\x5a\xb3\x67\x1d\x6b\x99\x58\x3e\x60\x97\x51\x33\x7d\x85\x4a\x24\x76\x8b\x43\x29\x1f\xd1\x34\x62\x14\xdf\x3d\x6f\x09\xcd\x26\x78\x02\xc3\x2f\x75\x33\xe9\x10\x56\x38\xe7\x19\x5b\x25\xf5\x02\x4c\x2e\xfb\x0b\x41\x8c\x9a\xd7\x61\x87\x94\xde\x6c\x9a\x86\xc5\x7b\x91\x88\xcc\x76\xa0\xa2\xf3\x55\xab\xac\xfa\x58\xb6\xbe\xe1\x4f\xbd\xb0\xe8\x42\xd4\xea\x9f\x09\xdf\xe4\x96\x04\xc2\xf6\x8d\x13\xc9\xf8\x84\x1e\xf8\xd2\xbb\x3d\xf3\xdc\xb2\x30\xee\xce\xa9\x27\xe5\xc0\xa0\x2a\x3c\x7a\x47\xb1\x37\x74\x4e\xbc\x2a\x66\x55\xab\x21\x68\x5c\xa6\x10\x42\x63\x85\x1b\x4c\x6a\x88\x06\x5e\x71\x9f\x0d\x50\x78\x92\x64\x0a\x0f\xd9\x6f\x04\x06\xd4\x72\x16\x1d\xc3\x79\x18\x14\xce\x48\x32\x2b\xed\x43\x3c\x22\xe0\x5e\x2e\x39\xf7\x55\x20\x30\xfa\x01\xec\x9a\xb7\x0a\xe2\x93\xba\x17\xf0\x88\xad\x1c\xfe\x81\xa0\x2d\xd4\xbe\x83\x26\xda\xb7\x8e\x3b\xc8\xac\x99\x30\xc6\xa5\x94\x59\x9c\xd2\xdf\x52\x92\xdb\xd2\x4f\x80\xc0\xc5\x44\x8e\xc9\xc8\x75\xa4\xf6\xeb\x7e\xaa\xff\xe6\x63\xb8\xe4\xf1\x68\xb6\xed\xfc\xb1\x0c\x0a\x67\xba\x02\x03\x6a\xa7\x10\x18\x7d\xac\x1e\x11\x70\x9d\x34\x2e\x53\x96\x3a\x27\x5e\x8b\x28\x3c\x49\x80\x26\x35\x44\xe9\x7c\x42\x0f\xe2\x72\x4b\x02\xff\x60\x50\x15\xf4\x6e\x59\x18\xc5\x44\x66\x3b\xce\x4a\x6f\x36\xd3\x58\x74\x21\xd8\x56\x7d\x2c\x7a\x37\xa1\x0c\x71\x39\xa8\x01\x6c\x2b\xb3\x16\x67\x25\xba\x1b\x56\x0f\x85\x38\x5d\x01\x8c\x35\x40\x13\x97\x22\x4b\x1d\x9e\x2f\x22\x47\xe9\x64\x29\x49\xe0\x69\x34\x5b\xfb\x7e\x3f\x55\xf2\x73\x0e\x7f\xcd\x50\x05\x71\xc4\x5d\x18\x63\xdf\x4a\x13\x6d\xd6\x47\xca\xd7\x31\xdc\xc1\xd9\x38\xd1\xdc\xcb\x23\xc6\xd7\xc5\x2a\xcb\xe6\xef\x15\xe8\xed\xe1\x1c\xe5\xf0\xf3\x07\xf2\xfb\xfd\x0e\xff\x92\xa7\x79\xb4\x99\xa9\x70\xb9\x84\xbb\x6b\xae\x8f\xb5\x62\xa3\xbe\x9f\x5d\x80\xb5\x91\x54\x8d\xa8\x83\x4f\x9a\xa3\x8d\x46\x97");
  static U3 = rawToIntArray("\x00\x00\x00\x00\x0d\x0b\x0e\x09\x1a\x16\x1c\x12\x17\x1d\x12\x1b\x34\x2c\x38\x24\x39\x27\x36\x2d\x2e\x3a\x24\x36\x23\x31\x2a\x3f\x68\x58\x70\x48\x65\x53\x7e\x41\x72\x4e\x6c\x5a\x7f\x45\x62\x53\x5c\x74\x48\x6c\x51\x7f\x46\x65\x46\x62\x54\x7e\x4b\x69\x5a\x77\xd0\xb0\xe0\x90\xdd\xbb\xee\x99\xca\xa6\xfc\x82\xc7\xad\xf2\x8b\xe4\x9c\xd8\xb4\xe9\x97\xd6\xbd\xfe\x8a\xc4\xa6\xf3\x81\xca\xaf\xb8\xe8\x90\xd8\xb5\xe3\x9e\xd1\xa2\xfe\x8c\xca\xaf\xf5\x82\xc3\x8c\xc4\xa8\xfc\x81\xcf\xa6\xf5\x96\xd2\xb4\xee\x9b\xd9\xba\xe7\xbb\x7b\xdb\x3b\xb6\x70\xd5\x32\xa1\x6d\xc7\x29\xac\x66\xc9\x20\x8f\x57\xe3\x1f\x82\x5c\xed\x16\x95\x41\xff\x0d\x98\x4a\xf1\x04\xd3\x23\xab\x73\xde\x28\xa5\x7a\xc9\x35\xb7\x61\xc4\x3e\xb9\x68\xe7\x0f\x93\x57\xea\x04\x9d\x5e\xfd\x19\x8f\x45\xf0\x12\x81\x4c\x6b\xcb\x3b\xab\x66\xc0\x35\xa2\x71\xdd\x27\xb9\x7c\xd6\x29\xb0\x5f\xe7\x03\x8f\x52\xec\x0d\x86\x45\xf1\x1f\x9d\x48\xfa\x11\x94\x03\x93\x4b\xe3\x0e\x98\x45\xea\x19\x85\x57\xf1\x14\x8e\x59\xf8\x37\xbf\x73\xc7\x3a\xb4\x7d\xce\x2d\xa9\x6f\xd5\x20\xa2\x61\xdc\x6d\xf6\xad\x76\x60\xfd\xa3\x7f\x77\xe0\xb1\x64\x7a\xeb\xbf\x6d\x59\xda\x95\x52\x54\xd1\x9b\x5b\x43\xcc\x89\x40\x4e\xc7\x87\x49\x05\xae\xdd\x3e\x08\xa5\xd3\x37\x1f\xb8\xc1\x2c\x12\xb3\xcf\x25\x31\x82\xe5\x1a\x3c\x89\xeb\x13\x2b\x94\xf9\x08\x26\x9f\xf7\x01\xbd\x46\x4d\xe6\xb0\x4d\x43\xef\xa7\x50\x51\xf4\xaa\x5b\x5f\xfd\x89\x6a\x75\xc2\x84\x61\x7b\xcb\x93\x7c\x69\xd0\x9e\x77\x67\xd9\xd5\x1e\x3d\xae\xd8\x15\x33\xa7\xcf\x08\x21\xbc\xc2\x03\x2f\xb5\xe1\x32\x05\x8a\xec\x39\x0b\x83\xfb\x24\x19\x98\xf6\x2f\x17\x91\xd6\x8d\x76\x4d\xdb\x86\x78\x44\xcc\x9b\x6a\x5f\xc1\x90\x64\x56\xe2\xa1\x4e\x69\xef\xaa\x40\x60\xf8\xb7\x52\x7b\xf5\xbc\x5c\x72\xbe\xd5\x06\x05\xb3\xde\x08\x0c\xa4\xc3\x1a\x17\xa9\xc8\x14\x1e\x8a\xf9\x3e\x21\x87\xf2\x30\x28\x90\xef\x22\x33\x9d\xe4\x2c\x3a\x06\x3d\x96\xdd\x0b\x36\x98\xd4\x1c\x2b\x8a\xcf\x11\x20\x84\xc6\x32\x11\xae\xf9\x3f\x1a\xa0\xf0\x28\x07\xb2\xeb\x25\x0c\xbc\xe2\x6e\x65\xe6\x95\x63\x6e\xe8\x9c\x74\x73\xfa\x87\x79\x78\xf4\x8e\x5a\x49\xde\xb1\x57\x42\xd0\xb8\x40\x5f\xc2\xa3\x4d\x54\xcc\xaa\xda\xf7\x41\xec\xd7\xfc\x4f\xe5\xc0\xe1\x5d\xfe\xcd\xea\x53\xf7\xee\xdb\x79\xc8\xe3\xd0\x77\xc1\xf4\xcd\x65\xda\xf9\xc6\x6b\xd3\xb2\xaf\x31\xa4\xbf\xa4\x3f\xad\xa8\xb9\x2d\xb6\xa5\xb2\x23\xbf\x86\x83\x09\x80\x8b\x88\x07\x89\x9c\x95\x15\x92\x91\x9e\x1b\x9b\x0a\x47\xa1\x7c\x07\x4c\xaf\x75\x10\x51\xbd\x6e\x1d\x5a\xb3\x67\x3e\x6b\x99\x58\x33\x60\x97\x51\x24\x7d\x85\x4a\x29\x76\x8b\x43\x62\x1f\xd1\x34\x6f\x14\xdf\x3d\x78\x09\xcd\x26\x75\x02\xc3\x2f\x56\x33\xe9\x10\x5b\x38\xe7\x19\x4c\x25\xf5\x02\x41\x2e\xfb\x0b\x61\x8c\x9a\xd7\x6c\x87\x94\xde\x7b\x9a\x86\xc5\x76\x91\x88\xcc\x55\xa0\xa2\xf3\x58\xab\xac\xfa\x4f\xb6\xbe\xe1\x42\xbd\xb0\xe8\x09\xd4\xea\x9f\x04\xdf\xe4\x96\x13\xc2\xf6\x8d\x1e\xc9\xf8\x84\x3d\xf8\xd2\xbb\x30\xf3\xdc\xb2\x27\xee\xce\xa9\x2a\xe5\xc0\xa0\xb1\x3c\x7a\x47\xbc\x37\x74\x4e\xab\x2a\x66\x55\xa6\x21\x68\x5c\x85\x10\x42\x63\x88\x1b\x4c\x6a\x9f\x06\x5e\x71\x92\x0d\x50\x78\xd9\x64\x0a\x0f\xd4\x6f\x04\x06\xc3\x72\x16\x1d\xce\x79\x18\x14\xed\x48\x32\x2b\xe0\x43\x3c\x22\xf7\x5e\x2e\x39\xfa\x55\x20\x30\xb7\x01\xec\x9a\xba\x0a\xe2\x93\xad\x17\xf0\x88\xa0\x1c\xfe\x81\x83\x2d\xd4\xbe\x8e\x26\xda\xb7\x99\x3b\xc8\xac\x94\x30\xc6\xa5\xdf\x59\x9c\xd2\xd2\x52\x92\xdb\xc5\x4f\x80\xc0\xc8\x44\x8e\xc9\xeb\x75\xa4\xf6\xe6\x7e\xaa\xff\xf1\x63\xb8\xe4\xfc\x68\xb6\xed\x67\xb1\x0c\x0a\x6a\xba\x02\x03\x7d\xa7\x10\x18\x70\xac\x1e\x11\x53\x9d\x34\x2e\x5e\x96\x3a\x27\x49\x8b\x28\x3c\x44\x80\x26\x35\x0f\xe9\x7c\x42\x02\xe2\x72\x4b\x15\xff\x60\x50\x18\xf4\x6e\x59\x3b\xc5\x44\x66\x36\xce\x4a\x6f\x21\xd3\x58\x74\x2c\xd8\x56\x7d\x0c\x7a\x37\xa1\x01\x71\x39\xa8\x16\x6c\x2b\xb3\x1b\x67\x25\xba\x38\x56\x0f\x85\x35\x5d\x01\x8c\x22\x40\x13\x97\x2f\x4b\x1d\x9e\x64\x22\x47\xe9\x69\x29\x49\xe0\x7e\x34\x5b\xfb\x73\x3f\x55\xf2\x50\x0e\x7f\xcd\x5d\x05\x71\xc4\x4a\x18\x63\xdf\x47\x13\x6d\xd6\xdc\xca\xd7\x31\xd1\xc1\xd9\x38\xc6\xdc\xcb\x23\xcb\xd7\xc5\x2a\xe8\xe6\xef\x15\xe5\xed\xe1\x1c\xf2\xf0\xf3\x07\xff\xfb\xfd\x0e\xb4\x92\xa7\x79\xb9\x99\xa9\x70\xae\x84\xbb\x6b\xa3\x8f\xb5\x62\x80\xbe\x9f\x5d\x8d\xb5\x91\x54\x9a\xa8\x83\x4f\x97\xa3\x8d\x46");
  static U4 = rawToIntArray("\x00\x00\x00\x00\x09\x0d\x0b\x0e\x12\x1a\x16\x1c\x1b\x17\x1d\x12\x24\x34\x2c\x38\x2d\x39\x27\x36\x36\x2e\x3a\x24\x3f\x23\x31\x2a\x48\x68\x58\x70\x41\x65\x53\x7e\x5a\x72\x4e\x6c\x53\x7f\x45\x62\x6c\x5c\x74\x48\x65\x51\x7f\x46\x7e\x46\x62\x54\x77\x4b\x69\x5a\x90\xd0\xb0\xe0\x99\xdd\xbb\xee\x82\xca\xa6\xfc\x8b\xc7\xad\xf2\xb4\xe4\x9c\xd8\xbd\xe9\x97\xd6\xa6\xfe\x8a\xc4\xaf\xf3\x81\xca\xd8\xb8\xe8\x90\xd1\xb5\xe3\x9e\xca\xa2\xfe\x8c\xc3\xaf\xf5\x82\xfc\x8c\xc4\xa8\xf5\x81\xcf\xa6\xee\x96\xd2\xb4\xe7\x9b\xd9\xba\x3b\xbb\x7b\xdb\x32\xb6\x70\xd5\x29\xa1\x6d\xc7\x20\xac\x66\xc9\x1f\x8f\x57\xe3\x16\x82\x5c\xed\x0d\x95\x41\xff\x04\x98\x4a\xf1\x73\xd3\x23\xab\x7a\xde\x28\xa5\x61\xc9\x35\xb7\x68\xc4\x3e\xb9\x57\xe7\x0f\x93\x5e\xea\x04\x9d\x45\xfd\x19\x8f\x4c\xf0\x12\x81\xab\x6b\xcb\x3b\xa2\x66\xc0\x35\xb9\x71\xdd\x27\xb0\x7c\xd6\x29\x8f\x5f\xe7\x03\x86\x52\xec\x0d\x9d\x45\xf1\x1f\x94\x48\xfa\x11\xe3\x03\x93\x4b\xea\x0e\x98\x45\xf1\x19\x85\x57\xf8\x14\x8e\x59\xc7\x37\xbf\x73\xce\x3a\xb4\x7d\xd5\x2d\xa9\x6f\xdc\x20\xa2\x61\x76\x6d\xf6\xad\x7f\x60\xfd\xa3\x64\x77\xe0\xb1\x6d\x7a\xeb\xbf\x52\x59\xda\x95\x5b\x54\xd1\x9b\x40\x43\xcc\x89\x49\x4e\xc7\x87\x3e\x05\xae\xdd\x37\x08\xa5\xd3\x2c\x1f\xb8\xc1\x25\x12\xb3\xcf\x1a\x31\x82\xe5\x13\x3c\x89\xeb\x08\x2b\x94\xf9\x01\x26\x9f\xf7\xe6\xbd\x46\x4d\xef\xb0\x4d\x43\xf4\xa7\x50\x51\xfd\xaa\x5b\x5f\xc2\x89\x6a\x75\xcb\x84\x61\x7b\xd0\x93\x7c\x69\xd9\x9e\x77\x67\xae\xd5\x1e\x3d\xa7\xd8\x15\x33\xbc\xcf\x08\x21\xb5\xc2\x03\x2f\x8a\xe1\x32\x05\x83\xec\x39\x0b\x98\xfb\x24\x19\x91\xf6\x2f\x17\x4d\xd6\x8d\x76\x44\xdb\x86\x78\x5f\xcc\x9b\x6a\x56\xc1\x90\x64\x69\xe2\xa1\x4e\x60\xef\xaa\x40\x7b\xf8\xb7\x52\x72\xf5\xbc\x5c\x05\xbe\xd5\x06\x0c\xb3\xde\x08\x17\xa4\xc3\x1a\x1e\xa9\xc8\x14\x21\x8a\xf9\x3e\x28\x87\xf2\x30\x33\x90\xef\x22\x3a\x9d\xe4\x2c\xdd\x06\x3d\x96\xd4\x0b\x36\x98\xcf\x1c\x2b\x8a\xc6\x11\x20\x84\xf9\x32\x11\xae\xf0\x3f\x1a\xa0\xeb\x28\x07\xb2\xe2\x25\x0c\xbc\x95\x6e\x65\xe6\x9c\x63\x6e\xe8\x87\x74\x73\xfa\x8e\x79\x78\xf4\xb1\x5a\x49\xde\xb8\x57\x42\xd0\xa3\x40\x5f\xc2\xaa\x4d\x54\xcc\xec\xda\xf7\x41\xe5\xd7\xfc\x4f\xfe\xc0\xe1\x5d\xf7\xcd\xea\x53\xc8\xee\xdb\x79\xc1\xe3\xd0\x77\xda\xf4\xcd\x65\xd3\xf9\xc6\x6b\xa4\xb2\xaf\x31\xad\xbf\xa4\x3f\xb6\xa8\xb9\x2d\xbf\xa5\xb2\x23\x80\x86\x83\x09\x89\x8b\x88\x07\x92\x9c\x95\x15\x9b\x91\x9e\x1b\x7c\x0a\x47\xa1\x75\x07\x4c\xaf\x6e\x10\x51\xbd\x67\x1d\x5a\xb3\x58\x3e\x6b\x99\x51\x33\x60\x97\x4a\x24\x7d\x85\x43\x29\x76\x8b\x34\x62\x1f\xd1\x3d\x6f\x14\xdf\x26\x78\x09\xcd\x2f\x75\x02\xc3\x10\x56\x33\xe9\x19\x5b\x38\xe7\x02\x4c\x25\xf5\x0b\x41\x2e\xfb\xd7\x61\x8c\x9a\xde\x6c\x87\x94\xc5\x7b\x9a\x86\xcc\x76\x91\x88\xf3\x55\xa0\xa2\xfa\x58\xab\xac\xe1\x4f\xb6\xbe\xe8\x42\xbd\xb0\x9f\x09\xd4\xea\x96\x04\xdf\xe4\x8d\x13\xc2\xf6\x84\x1e\xc9\xf8\xbb\x3d\xf8\xd2\xb2\x30\xf3\xdc\xa9\x27\xee\xce\xa0\x2a\xe5\xc0\x47\xb1\x3c\x7a\x4e\xbc\x37\x74\x55\xab\x2a\x66\x5c\xa6\x21\x68\x63\x85\x10\x42\x6a\x88\x1b\x4c\x71\x9f\x06\x5e\x78\x92\x0d\x50\x0f\xd9\x64\x0a\x06\xd4\x6f\x04\x1d\xc3\x72\x16\x14\xce\x79\x18\x2b\xed\x48\x32\x22\xe0\x43\x3c\x39\xf7\x5e\x2e\x30\xfa\x55\x20\x9a\xb7\x01\xec\x93\xba\x0a\xe2\x88\xad\x17\xf0\x81\xa0\x1c\xfe\xbe\x83\x2d\xd4\xb7\x8e\x26\xda\xac\x99\x3b\xc8\xa5\x94\x30\xc6\xd2\xdf\x59\x9c\xdb\xd2\x52\x92\xc0\xc5\x4f\x80\xc9\xc8\x44\x8e\xf6\xeb\x75\xa4\xff\xe6\x7e\xaa\xe4\xf1\x63\xb8\xed\xfc\x68\xb6\x0a\x67\xb1\x0c\x03\x6a\xba\x02\x18\x7d\xa7\x10\x11\x70\xac\x1e\x2e\x53\x9d\x34\x27\x5e\x96\x3a\x3c\x49\x8b\x28\x35\x44\x80\x26\x42\x0f\xe9\x7c\x4b\x02\xe2\x72\x50\x15\xff\x60\x59\x18\xf4\x6e\x66\x3b\xc5\x44\x6f\x36\xce\x4a\x74\x21\xd3\x58\x7d\x2c\xd8\x56\xa1\x0c\x7a\x37\xa8\x01\x71\x39\xb3\x16\x6c\x2b\xba\x1b\x67\x25\x85\x38\x56\x0f\x8c\x35\x5d\x01\x97\x22\x40\x13\x9e\x2f\x4b\x1d\xe9\x64\x22\x47\xe0\x69\x29\x49\xfb\x7e\x34\x5b\xf2\x73\x3f\x55\xcd\x50\x0e\x7f\xc4\x5d\x05\x71\xdf\x4a\x18\x63\xd6\x47\x13\x6d\x31\xdc\xca\xd7\x38\xd1\xc1\xd9\x23\xc6\xdc\xcb\x2a\xcb\xd7\xc5\x15\xe8\xe6\xef\x1c\xe5\xed\xe1\x07\xf2\xf0\xf3\x0e\xff\xfb\xfd\x79\xb4\x92\xa7\x70\xb9\x99\xa9\x6b\xae\x84\xbb\x62\xa3\x8f\xb5\x5d\x80\xbe\x9f\x54\x8d\xb5\x91\x4f\x9a\xa8\x83\x46\x97\xa3\x8d");


  key = null //needs to be an array
  _Ke = null
  _Kd = null

  constructor(key) {
    this.key = key
    this._prepare()
  }


  function _prepare() {

    local rounds = numberOfRounds[ this.key.len().tostring() ];
    if (rounds == null) {
      throw "invalid key size (must be 16, 24 or 32 bytes)"
    }

    // encryption round keys
    this._Ke = [];

    // decryption round keys
    this._Kd = [];

    for (local i = 0; i <= rounds; i++) {
      this._Ke.push([0, 0, 0, 0]);
      this._Kd.push([0, 0, 0, 0]);
    }

    local roundKeyCount = (rounds + 1) * 4;
    local KC = this.key.len() / 4;

    // convert the key into ints
    local tk = convertToInt32(this.key);

    // copy values into round key arrays
    local index;
    for (local i = 0; i < KC; i++) {
      index = i >> 2;
      this._Ke[index][i % 4] = tk[i];
      this._Kd[rounds - index][i % 4] = tk[i];
    }

    // key expansion (fips-197 section 5.2)
    local rconpointer = 0;
    local t = KC
    local tt = null
    while (t < roundKeyCount) {
      tt = tk[KC - 1];
      tk[0] = tk[0] ^ ((S[(tt >> 16) & 0xFF] << 24) ^
                (S[(tt >>  8) & 0xFF] << 16) ^
                (S[ tt        & 0xFF] <<  8) ^
                 S[(tt >> 24) & 0xFF]        ^
                (rcon[rconpointer] << 24));
      rconpointer += 1;

      // key expansion (for non-256 bit)
      if (KC != 8) {
        for (local i = 1; i < KC; i++) {
          tk[i] = tk[i] ^ tk[i - 1];
        }

      // key expansion for 256-bit keys is "slightly different" (fips-197)
      } else {
        for (local i = 1; i < (KC / 2); i++) {
          tk[i] = tk[i] ^ tk[i - 1];
        }
        tt = tk[(KC / 2) - 1];

        tk[KC / 2] = tk[KC / 2] ^ (S[ tt        & 0xFF]        ^
                      (S[(tt >>  8) & 0xFF] <<  8) ^
                      (S[(tt >> 16) & 0xFF] << 16) ^
                      (S[(tt >> 24) & 0xFF] << 24));

        for (local i = (KC / 2) + 1; i < KC; i++) {
          tk[i] = tk[i] ^ tk[i - 1];
        }
      }

      // copy values into round key arrays
      local i = 0
      local r = null
      local c = null
      while (i < KC && t < roundKeyCount) {
        r = t >> 2;
        c = t % 4;
        this._Ke[r][c] = tk[i];
        this._Kd[rounds - r][c] = tk[i++];
        t++;
      }
    }

    // inverse-cipher-ify the decryption round key (fips-197 section 5.3)
    for (local r = 1; r < rounds; r++) {
      for (local c = 0; c < 4; c++) {
          tt = this._Kd[r][c];
          this._Kd[r][c] = (U1[(tt >> 24) & 0xFF] ^
                            U2[(tt >> 16) & 0xFF] ^
                            U3[(tt >>  8) & 0xFF] ^
                            U4[ tt        & 0xFF]);
      }
    }
  }

  function encrypt(plainblob) {
    if (plainblob.len() != 16) {
      throw "invalid plainblob size (must be 16 bytes)"
    }

    local rounds = this._Ke.len() - 1;
    local a = [0, 0, 0, 0];

    // convert plaintext to (ints ^ key)
    local t = convertToInt32(plainblob);
    for (local i = 0; i < 4; i++) {
      t[i] = t[i] ^ this._Ke[0][i];
    }

    // apply round transforms
    for (local r = 1; r < rounds; r++) {
      for (local i = 0; i < 4; i++) {
        a[i] = (T1[(t[ i         ] >> 24) & 0xff] ^
                T2[(t[(i + 1) % 4] >> 16) & 0xff] ^
                T3[(t[(i + 2) % 4] >>  8) & 0xff] ^
                T4[ t[(i + 3) % 4]        & 0xff] ^
                this._Ke[r][i]);
      }
      t = a.slice(0);
    }

    // the last round is special
    local result = blob(16)
    local tt = null;
    for (local i = 0; i < 4; i++) {
      tt = this._Ke[rounds][i];
      result[4 * i    ] = (S[(t[ i         ] >> 24) & 0xff] ^ (tt >> 24)) & 0xff;
      result[4 * i + 1] = (S[(t[(i + 1) % 4] >> 16) & 0xff] ^ (tt >> 16)) & 0xff;
      result[4 * i + 2] = (S[(t[(i + 2) % 4] >>  8) & 0xff] ^ (tt >>  8)) & 0xff;
      result[4 * i + 3] = (S[ t[(i + 3) % 4]        & 0xff] ^  tt       ) & 0xff;
    }

    return result;
  }

  function decrypt(cipherblob) {
    if (cipherblob.len() != 16) {
      throw "invalid cipherblob size (must be 16 bytes)"
    }

    local rounds = this._Kd.len() - 1;
    local a = [0, 0, 0, 0];

    // convert plaintext to (ints ^ key)
    local t = convertToInt32(cipherblob);
    for (local i = 0; i < 4; i++) {
        t[i] = t[i] ^ this._Kd[0][i];
    }

    // apply round transforms
    for (local r = 1; r < rounds; r++) {
      for (local i = 0; i < 4; i++) {
        a[i] = (T5[(t[ i          ] >> 24) & 0xff] ^
                T6[(t[(i + 3) % 4] >> 16) & 0xff] ^
                T7[(t[(i + 2) % 4] >>  8) & 0xff] ^
                T8[ t[(i + 1) % 4]        & 0xff] ^
                this._Kd[r][i]);
      }
      t = a.slice(0);
    }

    // the last round is special
    local result = blob(16)
    local tt = null
    for (local i = 0; i < 4; i++) {
      tt = this._Kd[rounds][i];
      result[4 * i    ] = (Si[(t[ i         ] >> 24) & 0xff] ^ (tt >> 24)) & 0xff;
      result[4 * i + 1] = (Si[(t[(i + 3) % 4] >> 16) & 0xff] ^ (tt >> 16)) & 0xff;
      result[4 * i + 2] = (Si[(t[(i + 2) % 4] >>  8) & 0xff] ^ (tt >>  8)) & 0xff;
      result[4 * i + 3] = (Si[ t[(i + 1) % 4]        & 0xff] ^  tt       ) & 0xff;
    }

    return result;
  }

  function convertToInt32(bytes) {
    local result = [];
    for (local i = 0; i < bytes.len(); i += 4) {
      result.push(
        (bytes[i    ] << 24) |
        (bytes[i + 1] << 16) |
        (bytes[i + 2] <<  8) |
         bytes[i + 3]
      );
    }
    return result;
  }
}


class AES_CBC {

  _iv = null
  _aes = null

  constructor(key, iv) {

    if (!iv) {
      iv = blob(16);

    } else if (iv.len() != 16) {
      throw "invalid initialation vector size (must be 16 bytes)"
    }

    this._iv = iv //createBuffer(iv);

    this._aes = AES(key);
  }

  function encrypt(plainblob) {
    if ((plainblob.len() % 16) != 0) {
      throw "invalid plainblob size (must be multiple of 16 bytes)"
    }

    local cipherblob = blob(plainblob.len());
    local block = blob(16);

    local lastCipherblock = this._iv

    for (local i = 0; i < plainblob.len(); i += 16) {
      _blobcopy(plainblob, block, 0, i, i + 16);

      for (local j = 0; j < 16; j++) {
        block[j] = block[j] ^ lastCipherblock[j];
      }

      lastCipherblock = this._aes.encrypt(block);
      _blobcopy(lastCipherblock, cipherblob, i, 0, 16);
    }

    return cipherblob;
  }

  function decrypt(cipherblob) {
    if ((cipherblob.len() % 16) != 0) {
      throw "invalid cipherblob size (must be multiple of 16 bytes)"
    }

    local plainblob = blob(cipherblob.len());
    local block = blob(16);

    local lastCipherblock = this._iv

    for (local i = 0; i < cipherblob.len(); i += 16) {
      _blobcopy(cipherblob, block, 0, i, i + 16);
      block = this._aes.decrypt(block);

      for (local j = 0; j < 16; j++) {
        plainblob[i + j] = block[j] ^ lastCipherblock[j];
      }

      _blobcopy(cipherblob, lastCipherblock, 0, i, i + 16);
    }

    return plainblob;
  }

  function _blobcopy(sourceBlob, targetBlob, targetStart, sourceStart, sourceEnd) {
    sourceBlob.seek(sourceStart)
    targetBlob.seek(targetStart)
    targetBlob.writeblob(sourceBlob.readblob(sourceEnd - sourceStart))
  }

}
/**
 * Crunch - Arbitrary-precision integer arithmetic library
 * Copyright (C) 2014 Nenad Vukicevic crunch.secureroom.net/license
 */

/**
 * @module Crunch
 * Radix: 28 bits
 * Endianness: Big
 *
 * @param {boolean} rawIn   - expect 28-bit arrays
 * @param {boolean} rawOut  - return 28-bit arrays
 */
function Crunch (rawIn = false, rawOut = false) {
  /**
   * BEGIN CONSTANTS
   * primes and ptests for Miller-Rabin primality
   */

/* Remove support for primes until we need it.
  // sieve of Eratosthenes for first 1900 primes
  local primes = (function(n) {
    local arr  = array(math.ceil((n - 2) / 32).tointeger(), 0),
          maxi = (n - 3) / 2,
          p    = [2];

    for (local q = 3, i, index, bit; q < n; q += 2) {
      i     = (q - 3) / 2;
      index = i >> 5;
      bit   = i & 31;

      if ((arr[index] & (1 << bit)) == 0) {
        // q is prime
        p.push(q);
        i += q;

        for (local d = q; i < maxi; i += d) {
          index = i >> 5;
          bit   = i & 31;

          arr[index] = arr[index] | (1 << bit);
        }
      }
    }

    return p;

  })(16382);

  local ptests = primes.slice(0, 10).map(function (v) {
    return [v];
  });
*/

  /* END CONSTANTS */

  // Create a scope for the private methods so that they won't call the public
  // ones with the same name. This is different than JavaScript which has
  // different scoping rules.
  local priv = {

  function cut (x) {
    while (x[0] == 0 && x.len() > 1) {
      x.remove(0);
    }

    return x;
  }

  function cmp (x, y) {
    local xl = x.len(),
          yl = y.len(), i; //zero front pad problem

    if (xl < yl) {
      return -1;
    } else if (xl > yl) {
      return 1;
    }

    for (i = 0; i < xl; i++) {
      if (x[i] < y[i]) return -1;
      if (x[i] > y[i]) return 1;
    }

    return 0;
  }

  /**
   * Most significant bit, base 28, position from left
   */
  function msb (x) {
    if (x != 0) {
      local z = 0;
      for (local i = 134217728; i > x; z++) {
        i /= 2;
      }

      return z;
    }
  }

  /**
   * Most significant bit, base 14, position from left.
   * This is only needed for div14.
   */
  function msb14 (x) {
    if (x != 0) {
      local z = 0;
      // Start with 2^13.
      for (local i = 0x2000; i > x; z++) {
        i /= 2;
      }

      return z;
    }
  }

  /**
   * Least significant bit, position from right
   */
  function lsb (x) {
    if (x != 0) {
      local z = 0;
      for (; !(x & 1); z++) {
        x /= 2;
      }

      return z;
    }
  }

  function add (x, y) {
    local n = x.len(),
          t = y.len(),
          i = (n > t ? n : t),
          c = 0,
          z = array(i, 0);

    if (n < t) {
      x = concat(array(t-n, 0), x);
    } else if (n > t) {
      y = concat(array(n-t, 0), y);
    }

    for (i -= 1; i >= 0; i--) {
      z[i] = x[i] + y[i] + c;

      if (z[i] > 268435455) {
        c = 1;
        z[i] -= 268435456;
      } else {
        c = 0;
      }
    }

    if (c == 1) {
      z.insert(0, c);
    }

    return z;
  }

  /**
   * Effectively does abs(x) - abs(y).
   * The result is negative if cmp(x, y) < 0.
   */
  function sub (x, y, internal = false) {
    local n = x.len(),
          t = y.len(),
          i = (n > t ? n : t),
          c = 0,
          z = array(i, 0);

    if (n < t) {
      x = concat(array(t-n, 0), x);
    } else if (n > t) {
      y = concat(array(n-t, 0), y);
    }

    for (i -= 1; i >= 0; i--) {
      z[i] = x[i] - y[i] - c;

      if (z[i] < 0) {
        c = 1;
        z[i] += 268435456;
      } else {
        c = 0;
      }
    }

    if (c == 1 && !internal) {
      z = sub(array(z.len(), 0), z, true);
    }

    return z;
  }

  // The same as sub(x, y) except x and y are base 14.
  // This is only needed for div14.
  function sub14 (x, y, internal = false) {
    local n = x.len(),
          t = y.len(),
          i = (n > t ? n : t),
          c = 0,
          z = array(i, 0);

    if (n < t) {
      x = concat(array(t-n, 0), x);
    } else if (n > t) {
      y = concat(array(n-t, 0), y);
    }

    for (i -= 1; i >= 0; i--) {
      z[i] = x[i] - y[i] - c;

      if (z[i] < 0) {
        c = 1;
        // Add 2^14
        z[i] += 0x4000;
      } else {
        c = 0;
      }
    }

    if (c == 1 && !internal) {
      z = sub14(array(z.len(), 0), z, true);
    }

    return z;
  }

  /**
   * Signed Addition
   * Inputs and outputs are a table with arr and neg.
   */
  function sad (x, y) {
    local z;

    if (x.neg) {
      if (y.neg) {
        z = {arr = add(x.arr, y.arr), neg = true};
      } else {
        z = {arr = cut(sub(y.arr, x.arr, false)), neg = cmp(y.arr, x.arr) < 0};
      }
    } else {
      z = y.neg
        ? {arr = cut(sub(x.arr, y.arr, false)), neg = cmp(x.arr, y.arr) < 0}
        : {arr = add(x.arr, y.arr), neg = false};
    }

    return z;
  }

  /**
   * Signed Subtraction
   * Inputs and outputs are a table with arr and neg.
   */
  function ssb (x, y) {
    local z;

    if (x.neg) {
      if (y.neg) {
        z = {arr = cut(sub(y.arr, x.arr, false)), neg = cmp(y.arr, x.arr) < 0};
      } else {
        z = {arr = add(x.arr, y.arr), neg = true};
      }
    } else {
      z = y.neg
        ? {arr = add(x.arr, y.arr), neg = false}
        : {arr = cut(sub(x.arr, y.arr, false)), neg = cmp(x.arr, y.arr) < 0};
    }

    return z;
  }

  /**
   * Multiplication - HAC 14.12
   */
  function mul (x, y) {
    local yl, yh, c,
          n = x.len(),
          i = y.len(),
          z = array(n+i, 0);

    while (i--) {
      c = 0;

      yl = y[i] & 16383;
      yh = y[i] >> 14;

      for (local j = n-1, xl, xh, t1, t2; j >= 0; j--) {
        xl = x[j] & 16383;
        xh = x[j] >> 14;

        t1 = yh*xl + xh*yl;
        t2 = yl*xl + ((t1 & 16383) << 14) + z[j+i+1] + c;

        z[j+i+1] = t2 & 268435455;
        c = yh*xh + (t1 >> 14) + (t2 >> 28);
      }

      z[i] = c;
    }

    if (z[0] == 0) {
      z.remove(0);
    }

    return z;
  }

  // Same as mul(x, y) but x and y are base 14.
  // This is only needed for div14.
  function mul14 (x, y) {
    local yl, yh, c,
          n = x.len(),
          i = y.len(),
          z = array(n+i, 0);

    while (i--) {
      c = 0;

      // Mask with 2^7 - 1
      yl = y[i] & 0x7f;
      yh = y[i] >> 7;

      for (local j = n-1, xl, xh, t1, t2; j >= 0; j--) {
        xl = x[j] & 0x7f;
        xh = x[j] >> 7;

        t1 = yh*xl + xh*yl;
        t2 = yl*xl + ((t1 & 0x7f) << 7) + z[j+i+1] + c;

        // Mask with 2^14 - 1
        z[j+i+1] = t2 & 0x3fff;
        c = yh*xh + (t1 >> 7) + (t2 >> 14);
      }

      z[i] = c;
    }

    if (z[0] == 0) {
      z.remove(0);
    }

    return z;
  }

  /**
   *  Karatsuba Multiplication, works faster when numbers gets bigger
   */
/* Don't support mulk.
  function mulk (x, y) {
    local z, lx, ly, negx, negy, b;

    if (x.len() > y.len()) {
      z = x; x = y; y = z;
    }
    lx = x.len();
    ly = y.len();
    negx = x.negative,
    negy = y.negative;
    x.negative = false;
    y.negative = false;

    if (lx <= 100) {
      z = mul(x, y);
    } else if (ly / lx >= 2) {
      b = (ly + 1) >> 1;
      z = sad(
        lsh(mulk(x, y.slice(0, ly-b)), b * 28),
        mulk(x, y.slice(ly-b, ly))
      );
    } else {
      b = (ly + 1) >> 1;
      var
          x0 = x.slice(lx-b, lx),
          x1 = x.slice(0, lx-b),
          y0 = y.slice(ly-b, ly),
          y1 = y.slice(0, ly-b),
          z0 = mulk(x0, y0),
          z2 = mulk(x1, y1),
          z1 = ssb(sad(z0, z2), mulk(ssb(x1, x0), ssb(y1, y0)));
      z2 = lsh(z2, b * 2 * 28);
      z1 = lsh(z1, b * 28);

      z = sad(sad(z2, z1), z0);
    }

    z.negative = (negx ^ negy) ? true : false;
    x.negative = negx;
    y.negative = negy;

    return z;
  }
*/

  /**
   * Squaring - HAC 14.16
   */
  function sqr (x) {
    local l1, h1, t1, t2, c,
          i = x.len(),
          z = array(2*i, 0);

    while (i--) {
      l1 = x[i] & 16383;
      h1 = x[i] >> 14;

      t1 = 2*h1*l1;
      t2 = l1*l1 + ((t1 & 16383) << 14) + z[2*i+1];

      z[2*i+1] = t2 & 268435455;
      c = h1*h1 + (t1 >> 14) + (t2 >> 28);

      for (local j = i-1, l2, h2; j >= 0; j--) {
        l2 = (2 * x[j]) & 16383;
        h2 = x[j] >> 13;

        t1 = h2*l1 + h1*l2;
        t2 = l2*l1 + ((t1 & 16383) << 14) + z[j+i+1] + c;
        z[j+i+1] = t2 & 268435455;
        c = h2*h1 + (t1 >> 14) + (t2 >> 28);
      }

      z[i] = c;
    }

    if (z[0] == 0) {
      z.remove(0);
    }

    return z;
  }

  function rsh (x, s) {
    local ss = s % 28,
          ls = math.floor(s/28).tointeger(),
          l  = x.len() - ls,
          z  = x.slice(0,l);

    if (ss) {
      while (--l) {
        z[l] = ((z[l] >> ss) | (z[l-1] << (28-ss))) & 268435455;
      }

      z[l] = z[l] >> ss;

      if (z[0] == 0) {
        z.remove(0);
      }
    }

    return z;
  }

  /**
   * Inputs and outputs are a table with arr and neg.
   * Call rsh, passing through neg.
   */
  function rshSigned (x, s) {
    return {arr = rsh(x.arr, s), neg = x.neg};
  }

  function lsh (x, s) {
    local ss = s % 28,
          ls = math.floor(s/28).tointeger(),
          l  = x.len(),
          z  = [],
          t  = 0;

    if (ss) {
      z.resize(l);
      while (l--) {
        z[l] = ((x[l] << ss) + t) & 268435455;
        t    = x[l] >>> (28 - ss);
      }

      if (t != 0) {
        z.insert(0, t);
      }
    } else {
      z = x;
    }

    return (ls) ? concat(z, array(ls, 0)) : z;
  }

  // x is a base 14 array.
  // This is only needed for div14.
  function lsh14 (x, s) {
    local ss = s % 14,
          ls = math.floor(s/14).tointeger(),
          l  = x.len(),
          z  = [],
          t  = 0;

    if (ss) {
      z.resize(l);
      while (l--) {
        // Mask with 2^14 - 1.
        z[l] = ((x[l] << ss) + t) & 0x3fff;
        t    = x[l] >>> (14 - ss);
      }

      if (t != 0) {
        z.insert(0, t);
      }
    } else {
      z = x;
    }

    return (ls) ? concat(z, array(ls, 0)) : z;
  }

  /**
   * Division - HAC 14.20
   */
  function div (x, y, internal) {
    local u, v, xt, yt, d, q, k, i, z,
          s = msb(y[0]) - 1;

    if (s > 0) {
      u = lsh(x, s);
      v = lsh(y, s);
    } else {
      u = x.slice(0);
      v = y.slice(0);
    }

    d  = u.len() - v.len();
    q  = [0];
    k  = concat(v, array(d, 0));
    yt = v.slice(0, 2);

    // only cmp as last resort
    while (u[0] > k[0] || (u[0] == k[0] && cmp(u, k) > -1)) {
      q[0]++;
      u = sub(u, k, false);
    }

    q.resize(d + 1);
    for (i = 1; i <= d; i++) {
      if (u[i-1] == v[0])
        q[i] = 268435455;
      else {
/* Avoid 64-bit arithmetic.
        local x1 = (u[i-1]*268435456 + u[i])/v[0];
*/
        local t14 = div14(toBase14(u.slice(i-1, i+1)), toBase14([v[0]]));
        // We expect the result to be less than 28 bits.
        local x1 = t14.len() == 1 ? t14[0] : t14[0] * 0x4000 + t14[1];
        q[i] = ~~x1;
      }

      xt = u.slice(i-1, i+2);

      while (cmp(mul([q[i]], yt), xt) > 0) {
        q[i]--;
      }

      k = concat(mul(v, [q[i]]), array(d-i, 0)); //concat after multiply, save cycles
      local u_negative = (cmp(u, k) < 0);
      u = sub(u, k, false);

      if (u_negative) {
        u = sub(concat(v, array(d-i, 0)), u, false);
        // Now, u is non-negative.
        q[i]--;
      }
    }

    if (internal) {
      z = (s > 0) ? rsh(cut(u), s) : cut(u);
    } else {
      z = cut(q);
    }

    return z;
  }

  // Convert the array from base 28 to base 14.
  // This is only needed for div14.
  function toBase14 (x) {
    local hi = x[0] >>> 14;
    // Mask with 2^14 - 1.
    local lo = x[0] & 0x3fff;
    local j, result;

    if (hi == 0) {
      result = array(1 + 2 * (x.len() - 1));
      result[0] = lo;
      j = 1;
    }
    else {
      result = array(2 + 2 * (x.len() - 1));
      result[0] = hi;
      result[1] = lo;
      j = 2;
    }

    for (local i = 1; i < x.len(); ++i) {
      result[j++] = x[i] >>> 14;
      result[j++] = x[i] & 0x3fff;
    }

    return result;
  }

  /**
   * Division base 14. 
   * We need this so that we can do 32-bit integer division on the Imp.
   */
  function div14 (x, y) {
    local u, v, xt, yt, d, q, k, i, z,
          s = msb14(y[0]) - 1;

    if (s > 0) {
      u = lsh14(x, s);
      v = lsh14(y, s);
    } else {
      u = x.slice(0);
      v = y.slice(0);
    }

    d  = u.len() - v.len();
    q  = [0];
    k  = concat(v, array(d, 0));
    yt = v.slice(0, 2);

    // only cmp as last resort
    while (u[0] > k[0] || (u[0] == k[0] && cmp(u, k) > -1)) {
      q[0]++;
      u = sub14(u, k);
    }

    q.resize(d + 1);
    for (i = 1; i <= d; i++) {
      if (u[i-1] == v[0])
        // Set to 2^14 - 1.
        q[i] = 0x3fff;
      else {
        // This is dividing a 28-bit value by a 14-bit value.
        local x1 = (u[i-1]*0x4000 + u[i])/v[0];
        q[i] = ~~x1;
      }

      xt = u.slice(i-1, i+2);

      while (cmp(mul14([q[i]], yt), xt) > 0) {
        q[i]--;
      }

      k = concat(mul14(v, [q[i]]), array(d-i, 0)); //concat after multiply, save cycles
      local u_negative = (cmp(u, k) < 0);
      u = sub14(u, k);

      if (u_negative) {
        u = sub14(concat(v, array(d-i, 0)), u, false);
        // Now, u is non-negative.
        q[i]--;
      }
    }

    z = cut(q);

    return z;
  }

  function mod (x, y) {
    switch (cmp(x, y)) {
      case -1:
        return x;
      case 0:
        return [0];
      default:
        return div(x, y, true);
    }
  }

  /**
   * Greatest Common Divisor - HAC 14.61 - Binary Extended GCD, used to calc inverse, x <= modulo, y <= exponent
   * Result is a table with arr and neg.
   */
  function gcd (x, y) {
    local min1 = lsb(x[x.len()-1]);
    local min2 = lsb(y[y.len()-1]);
    local g = (min1 < min2 ? min1 : min2),
          u = rsh(x, g),
          v = rsh(y, g),
          a = {arr = [1], neg = false}, b = {arr = [0], neg = false},
          c = {arr = [0], neg = false}, d = {arr = [1], neg = false}, s,
          xSigned = {arr = x, neg = false},
          ySigned = {arr = y, neg = false};

    while (u.len() != 1 || u[0] != 0) {
      s = lsb(u[u.len()-1]);
      u = rsh(u, s);
      while (s--) {
        if ((a.arr[a.arr.len()-1]&1) == 0 && (b.arr[b.arr.len()-1]&1) == 0) {
          a = rshSigned(a, 1);
          b = rshSigned(b, 1);
        } else {
          a = rshSigned(sad(a, ySigned), 1);
          b = rshSigned(ssb(b, xSigned), 1);
        }
      }

      s = lsb(v[v.len()-1]);
      v = rsh(v, s);
      while (s--) {
        if ((c.arr[c.arr.len()-1]&1) == 0 && (d.arr[d.arr.len()-1]&1) == 0) {
          c = rshSigned(c, 1);
          d = rshSigned(d, 1);
        } else {
          c = rshSigned(sad(c, ySigned), 1);
          d = rshSigned(ssb(d, xSigned), 1);
        }
      }

      if (cmp(u, v) >= 0) {
        u = sub(u, v, false);
        a = ssb(a, c);
        b = ssb(b, d);
      } else {
        v = sub(v, u, false);
        c = ssb(c, a);
        d = ssb(d, b);
      }
    }

    if (v.len() == 1 && v[0] == 1) {
      return d;
    }
  }

  /**
   * Inverse 1/x mod y
   */
  function inv (x, y) {
    local z = gcd(y, x);
    return (z != null && z.neg) ? sub(y, z.arr, false) : z.arr;
  }

  /**
   * Barret Modular Reduction - HAC 14.42
   */
  function bmr (x, m, mu = null) {
    local q1, q2, q3, r1, r2, z, s, k = m.len();

    if (cmp(x, m) < 0) {
      return x;
    }

    if (mu == null) {
      mu = div(concat([1], array(2*k, 0)), m, false);
    }

    q1 = x.slice(0, x.len()-(k-1));
    q2 = mul(q1, mu);
    q3 = q2.slice(0, q2.len()-(k+1));

    s  = x.len()-(k+1);
    r1 = (s > 0) ? x.slice(s) : x.slice(0);

    r2 = mul(q3, m);
    s  = r2.len()-(k+1);

    if (s > 0) {
      r2 = r2.slice(s);
    }

    z = cut(sub(r1, r2, false));

    while (cmp(z, m) >= 0) {
      z = cut(sub(z, m, false));
    }

    return z;
  }

  /**
   * Modular Exponentiation - HAC 14.76 Right-to-left binary exp
   */
  function exp (x, e, n) {
    local c = 268435456,
          r = [1],
          u = div(concat(r, array(2*n.len(), 0)), n, false);

    for (local i = e.len()-1; i >= 0; i--) {
      if (i == 0) {
        c = 1 << (27 - msb(e[0]));
      }

      for (local j = 1; j < c; j *= 2) {
        if (e[i] & j) {
          r = bmr(mul(r, x), n, u);
        }
        x = bmr(sqr(x), n, u);
      }
    }

    return bmr(mul(r, x), n, u);
  }

  /**
   * Garner's algorithm, modular exponentiation - HAC 14.71
   */
  function gar (x, p, q, d, u, dp1 = null, dq1 = null) {
    local vp, vq, t;

    if (dp1 == null) {
      dp1 = mod(d, dec(p));
      dq1 = mod(d, dec(q));
    }

    vp = exp(mod(x, p), dp1, p);
    vq = exp(mod(x, q), dq1, q);

    if (cmp(vq, vp) < 0) {
      t = cut(sub(vp, vq, false));
      t = cut(bmr(mul(t, u), q, null));
      t = cut(sub(q, t, false));
    } else {
      t = cut(sub(vq, vp, false));
      t = cut(bmr(mul(t, u), q, null)); //bmr instead of mod, div can fail because of precision
    }

    return cut(add(vp, mul(t, p)));
  }

  /**
   * Simple Mod - When n < 2^14
   */
/* Remove support for primes until we need it.
  function mds (x, n) {
    local z;
    for (local i = 0, z = 0, l = x.len(); i < l; i++) {
      z = ((x[i] >> 14) + (z << 14)) % n;
      z = ((x[i] & 16383) + (z << 14)) % n;
    }

    return z;
  }
*/

  function dec (x) {
    local z;

    if (x[x.len()-1] > 0) {
      z = x.slice(0);
      z[z.len()-1] -= 1;
    } else {
      z = sub(x, [1], false);
    }

    return z;
  }

  /**
   * Miller-Rabin Primality Test
   */
/* Remove support for primes until we need it.
  function mrb (x, iterations) {
    local m = dec(x),
          s = lsb(m[x.len()-1]),
          r = rsh(x, s);

    for (local i = 0, j, t, y; i < iterations; i++) {
      y = exp(ptests[i], r, x);

      if ( (y.len() > 1 || y[0] != 1) && cmp(y, m) != 0 ) {
        j = 1;
        t = true;

        while (t && s > j++) {
          y = mod(sqr(y), x);

          if (y.len() == 1 && y[0] == 1) {
            return false;
          }

          t = cmp(y, m) != 0;
        }

        if (t) {
          return false;
        }
      }
    }

    return true;
  }

  function tpr (x) {
    if (x.len() == 1 && x[0] < 16384 && primes.indexOf(x[0]) >= 0) {
      return true;
    }

    for (local i = 1, l = primes.len(); i < l; i++) {
      if (mds(x, primes[i]) == 0) {
        return false;
      }
    }

    return mrb(x, 3);
  }
*/

  /**
   * Quick add integer n to arbitrary precision integer x avoiding overflow
   */
/* Remove support for primes until we need it.
  function qad (x, n) {
    local l = x.len() - 1;

    if (x[l] + n < 268435456) {
      x[l] += n;
    } else {
      x = add(x, [n]);
    }

    return x;
  }

  function npr (x) {
    x = qad(x, 1 + x[x.len()-1] % 2);

    while (!tpr(x)) {
      x = qad(x, 2);
    }

    return x;
  }

  function fct (n) {
    local z = [1],
          a = [1];

    while (a[0]++ < n) {
      z = mul(z, a);
    }

    return z;
  }
*/

  /**
   * Convert byte array to 28 bit array
   * a[0] must be non-negative.
   */
  function ci (a) {
    local x = [0,0,0,0,0,0].slice((a.len()-1)%7),
          z = [];

    if (a[0] < 0) {
      throw "ci: a[0] is negative";
    }

    x = concat(x, a);

    for (local i = 0; i < x.len(); i += 7) {
      z.push(x[i]*1048576 + x[i+1]*4096 + x[i+2]*16 + (x[i+3]>>4));
      z.push((x[i+3]&15)*16777216 + x[i+4]*65536 + x[i+5]*256 + x[i+6]);
    }

    return cut(z);
  }

  /**
   * Convert 28 bit array to byte array
   */
  function co (a = null) {
    if (a != null) {
      local x = concat([0].slice((a.len()-1)%2), a),
            z = [];

      for (local u, v, i = 0; i < x.len();) {
        u = x[i++];
        v = x[i++];

        z.push(u >> 20);
        z.push(u >> 12 & 255);
        z.push(u >> 4 & 255);
        z.push((u << 4 | v >> 24) & 255);
        z.push(v >> 16 & 255);
        z.push(v >> 8 & 255);
        z.push(v & 255);
      }

      z = cut(z);

      return z;
    }
  }

/* Don't support stringify.
  function stringify (x) {
    local a = [],
          b = [10],
          z = [0],
          i = 0, q;

    do {
      q      = x;
      x      = div(q, b);
      a[i++] = sub(q, mul(b, x)).pop();
    } while (cmp(x, z));

    return a.reverse().join("");
  }
*/

/* Don't support parse.
  function parse (s) {
    local x = s.split(""),
          p = [1],
          a = [0],
          b = [10],
          n = false;

    if (x[0] == "-") {
      n = true;
      x.remove(0);
    }

    while (x.len()) {
      a = add(a, mul(p, [x.pop()]));
      p = mul(p, b);
    }

    a.negative = n;

    return a;
  }
*/

  /**
   * Imitate the JavaScript concat method to return a new array with the
   * concatenation of a1 and a2.
   * @param {Array} a1 The first array.
   * @param {Array} a2 The second array.
   * @return {Array} A new array.
   */
  function concat(a1, a2)
  {
    local result = a1.slice(0);
    result.extend(a2);
    return result;
  }

  // Imitate JavaScript apply. Squirrel has different scoping rules.
  function apply(func, args) {
    if (args.len() == 0) return func();
    else if (args.len() == 1) return func(args[0]);
    else if (args.len() == 2) return func(args[0], args[1]);
    else if (args.len() == 3) return func(args[0], args[1], args[2]);
    else if (args.len() == 4) return func(args[0], args[1], args[2], args[3]);
    else if (args.len() == 5)
      return func(args[0], args[1], args[2], args[3], args[4]);
    else if (args.len() == 6)
      return func(args[0], args[1], args[2], args[3], args[4], args[5]);
    else if (args.len() == 7)
      return func(args[0], args[1], args[2], args[3], args[4], args[5], args[6]);
  }

  }; // End priv.

  local transformIn = function(a) {
    return rawIn ? a : a.map(function (v) {
      return priv.ci(v.slice(0))
    });
  }

  local transformOut = function(x) {
    return rawOut ? x : priv.co(x);
  }

  return {
    /**
     * Return zero array length n
     *
     * @method zero
     * @param {Number} n
     * @return {Array} 0 length n
     */
    zero = function (n) {
      return array(n, 0);
    },

    /**
     * Signed Addition - Safe for signed MPI
     *
     * @method add
     * @param {Array} x
     * @param {Array} y
     * @return {Array} x + y
     */
/* Don't export add until we need it.
    add = function (x, y) {
      return transformOut(
        priv.apply(priv.add, transformIn([x, y]))
      );
    },
*/

    /**
     * Signed Subtraction - Safe for signed MPI
     *
     * @method sub
     * @param {Array} x
     * @param {Array} y
     * @return {Array} x - y
     */
/* Don't export sub until we need it.
    sub = function (x, y) {
      local args = transformIn([x, y]);
      if (priv.apply(priv.cmp, args) < 0)
        throw "Negative result for sub not supported";
      return transformOut(
        priv.apply(priv.sub, args)
      );
    },

    /**
     * Multiplication
     *
     * @method mul
     * @param {Array} x
     * @param {Array} y
     * @return {Array} x * y
     */
/* Don't export mul until we need it.
    mul = function (x, y) {
      return transformOut(
        priv.apply(priv.mul, transformIn([x, y]))
      );
    },
*/

    /**
     * Multiplication, with karatsuba method
     *
     * @method mulk
     * @param {Array} x
     * @param {Array} y
     * @return {Array} x * y
     */
/* Don't support mulk.
    mulk = function (x, y) {
      return transformOut(
        priv.apply(priv.mulk, transformIn([x, y]))
      );
    },
*/

    /**
     * Squaring
     *
     * @method sqr
     * @param {Array} x
     * @return {Array} x * x
     */
/* Don't export sqr until we need it.
    sqr = function (x) {
      return transformOut(
        priv.apply(priv.sqr, transformIn([x]))
      );
    },
*/

    /**
     * Modular Exponentiation
     *
     * @method exp
     * @param {Array} x
     * @param {Array} e
     * @param {Array} n
     * @return {Array} x^e % n
     */
    exp = function (x, e, n) {
      return transformOut(
        priv.apply(priv.exp, transformIn([x, e, n]))
      );
    },

    /**
     * Division
     *
     * @method div
     * @param {Array} x
     * @param {Array} y
     * @return {Array} x / y || undefined
     */
/* Don't export div until we need it.
    div = function (x, y) {
      if (y.len() != 1 || y[0] != 0) {
        return transformOut(
          priv.apply(priv.div, transformIn([x, y]))
        );
      }
    },
*/

    /**
     * Modulus
     *
     * @method mod
     * @param {Array} x
     * @param {Array} y
     * @return {Array} x % y
     */
/* Don't export mod until we need it.
    mod = function (x, y) {
      return transformOut(
        priv.apply(priv.mod, transformIn([x, y]))
      );
    },
*/

    /**
     * Barret Modular Reduction
     *
     * @method bmr
     * @param {Array} x
     * @param {Array} y
     * @param {Array} [mu]
     * @return {Array} x % y
     */
/* Don't export bmr until we need it.
    bmr = function (x, y, mu = null) {
      return transformOut(
        priv.apply(priv.bmr, transformIn([x, y, mu]))
      );
    },
*/

    /**
     * Garner's Algorithm
     *
     * @method gar
     * @param {Array} x
     * @param {Array} p
     * @param {Array} q
     * @param {Array} d
     * @param {Array} u
     * @param {Array} [dp1]
     * @param {Array} [dq1]
     * @return {Array} x^d % pq
     */
    gar = function (x, p, q, d, u, dp1 = null, dq1 = null) {
      return transformOut(
        priv.apply(priv.gar, transformIn([x, p, q, d, u, dp1, dq1]))
      );
    },

    /**
     * Mod Inverse
     *
     * @method inv
     * @param {Array} x
     * @param {Array} y
     * @return {Array} 1/x % y || undefined
     */
    inv = function (x, y) {
      return transformOut(
        priv.apply(priv.inv, transformIn([x, y]))
      );
    },

    /**
     * Remove leading zeroes
     *
     * @method cut
     * @param {Array} x
     * @return {Array} x without leading zeroes
     */
    cut = function (x) {
      return transformOut(
        priv.apply(priv.cut, transformIn([x]))
      );
    },


    /**
     * Factorial - for n < 268435456
     *
     * @method factorial
     * @param {Number} n
     * @return {Array} n!
     */
/* Don't export factorial until we need it.
    factorial = function (n) {
      return transformOut(
        priv.apply(priv.fct, [n%268435456])
      );
    },
*/

    /**
     * Bitwise AND, OR, XOR
     * Undefined if x and y different lengths
     *
     * @method OP
     * @param {Array} x
     * @param {Array} y
     * @return {Array} x OP y
     */
/* Don't export bitwise operations until we need them.
    and = function (x, y) {
      if (x.len() == y.len()) {
        for (local i = 0, z = []; i < x.len(); i++) { z[i] = x[i] & y[i] }
        return z;
      }
    },

    or = function (x, y) {
      if (x.len() == y.len()) {
        for (local i = 0, z = []; i < x.len(); i++) { z[i] = x[i] | y[i] }
        return z;
      }
    },

    xor = function (x, y) {
      if (x.len() == y.len()) {
        for (local i = 0, z = []; i < x.len(); i++) { z[i] = x[i] ^ y[i] }
        return z;
      }
    },
*/

    /**
     * Bitwise NOT
     *
     * @method not
     * @param {Array} x
     * @return {Array} NOT x
     */
/* Don't export bitwise operations until we need them.
    not = function (x) {
      for (local i = 0, z = [], m = rawIn ? 268435455 : 255; i < x.len(); i++) { z[i] = ~x[i] & m }
      return z;
    },
*/

    /**
     * Left Shift
     *
     * @method leftShift
     * @param {Array} x
     * @param {Integer} s
     * @return {Array} x << s
     */
/* Don't export bitwise operations until we need them.
    leftShift = function (x, s) {
      return transformOut(priv.lsh(transformIn([x]).pop(), s));
    },
*/

    /**
     * Zero-fill Right Shift
     *
     * @method rightShift
     * @param {Array} x
     * @param {Integer} s
     * @return {Array} x >>> s
     */
/* Don't export bitwise operations until we need them.
    rightShift = function (x, s) {
      return transformOut(priv.rsh(transformIn([x]).pop(), s));
    },
*/

    /**
     * Decrement
     *
     * @method decrement
     * @param {Array} x
     * @return {Array} x - 1
     */
/* Don't export decrement until we need it.
    decrement = function (x) {
      return transformOut(
        priv.apply(priv.dec, transformIn([x]))
      );
    },
*/

    /**
     * Compare values of two MPIs - Not safe for signed or leading zero MPI
     *
     * @method compare
     * @param {Array} x
     * @param {Array} y
     * @return {Number} 1: x > y
     *                  0: x = y
     *                 -1: x < y
     */
/* Don't export compare until we need it.
    compare = function (x, y) {
      return priv.cmp(x, y);
    },
*/

    /**
     * Find Next Prime
     *
     * @method nextPrime
     * @param {Array} x
     * @return {Array} 1st prime > x
     */
/* Remove support for primes until we need it.
    nextPrime = function (x) {
      return transformOut(
        priv.apply(priv.npr, transformIn([x]))
      );
    },
*/

    /**
     * Primality Test
     * Sieve then Miller-Rabin
     *
     * @method testPrime
     * @param {Array} x
     * @return {boolean} is prime
     */
/* Remove support for primes until we need it.
    testPrime = function (x) {
      return (x[x.len()-1] % 2 == 0) ? false : priv.apply(priv.tpr, transformIn([x]));
    },
*/

    /**
     * Array base conversion
     *
     * @method transform
     * @param {Array} x
     * @param {boolean} toRaw
     * @return {Array}  toRaw: 8 => 28-bit array
     *                 !toRaw: 28 => 8-bit array
     */
    transform = function (x, toRaw) {
      return toRaw ? priv.ci(x) : priv.co(x);
    }
//    ,

    /**
     * Integer to String conversion
     *
     * @method stringify
     * @param {Array} x
     * @return {String} base 10 number as string
     */
/* Don't support stringify.
    stringify = function (x) {
      return stringify(priv.ci(x));
    },
*/

    /**
     * String to Integer conversion
     *
     * @method parse
     * @param {String} s
     * @return {Array} x
     */
/* Don't support parse.
    parse = function (s) {
      return priv.co(parse(s));
    }
*/
  }
}
/**
 * Copyright (C) 2016-2017 Regents of the University of California.
 * @author: Jeff Thompson <jefft0@remap.ucla.edu>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * A copy of the GNU Lesser General Public License is in the file COPYING.
 */

/**
 * A MicroForwarder holds a PIT, FIB and faces to function as a simple NDN
 * forwarder. It has a single instance which you can access with
 * MicroForwarder.get().
 */
class MicroForwarder {
  PIT_ = null;   // array of PitEntry
  FIB_ = null;   // array of FibEntry
  faces_ = null; // array of ForwarderFace
  canForward_ = null; // function
  logLevel_ = 0; // integer
  debugEnable_ = false; // bool

  static localhostNamePrefix = Name("/localhost");
  static broadcastNamePrefix = Name("/ndn/broadcast");

  /**
   * Create a new MicroForwarder. You must call addFace(). If running on the Imp
   * device, call addFace("internal://agent", agent).
   * Normally you do not create a MicroForwader, but use the static get().
   */
  constructor()
  {
    PIT_ = [];
    FIB_ = [];
    faces_ = [];
  }

  /**
   * Get a singleton instance of a MicroForwarder.
   * @return {MicroForwarder} The singleton instance.
   */
  static function get()
  {
    if (MicroForwarder_instance == null)
      ::MicroForwarder_instance = MicroForwarder();
    return MicroForwarder_instance;
  }

  /**
   * Add a new face to communicate with the given transport. This immediately
   * connects using the connectionInfo.
   * @param {string} uri The URI to use in the faces/query and faces/list
   * commands.
   * @param {Transport} transport An object of a subclass of Transport to use
   * for communication. If the transport object has a "setOnReceivedObject"
   * method, then use it to set the onReceivedObject callback.
   * @param {TransportConnectionInfo} connectionInfo This must be a
   * ConnectionInfo from the same subclass of Transport as transport.
   * @return {integer} The new face ID.
   */
  function addFace(uri, transport, connectionInfo)
  {
    local face = null;
    local thisForwarder = this;
    if ("setOnReceivedObject" in transport)
      transport.setOnReceivedObject
        (function(obj) { thisForwarder.onReceivedObject(face, obj); });
    face = ForwarderFace(uri, transport);

    transport.connect
      (connectionInfo,
       { onReceivedElement = function(element) {
           thisForwarder.onReceivedElement(face, element); } },
       function(){});
    faces_.append(face);

    return face.faceId;
  }

  /**
   * Set the canForward callback. When the MicroForwarder receives an interest
   * which matches the routing prefix on a face, it calls canForward as
   * described below to check if it is OK to forward to the face. This can be
   * used to implement a simple forwarding strategy.
   * @param {function} canForward If not null, and the interest matches the
   * routePrefix of the outgoing face, then the MicroForwarder calls
   * canForward(interest, incomingFaceId, incomingFaceUri, outgoingFaceId,
   * outgoingFaceUri, routePrefix) where interest is the incoming Interest
   * object, incomingFaceId is the ID integer of the incoming face,
   * incomingFaceUri is the URI string of the incoming face, outgoingFaceId is
   * the ID integer of the outgoing face, outgoingFaceUri is the URI string of
   * the outgoing face, and routePrefix is the prefix Name of the matching
   * outgoing route. The canForward callback should return true if it is OK to
   * forward to the outgoing face, else false. Alternatively, if canForward
   * returns a non-negative float x, then forward after a delay of x seconds
   * using imp.wakeup (only supported on the Imp).
   * IMPORTANT: The canForward callback is called when the routePrefix matches,
   * even if the outgoing face is the same as the incoming face. So you must
   * check if incomingFaceId == outgoingFaceId and return false if you don't
   * want to forward to the same face.
   */
  function setCanForward(canForward) { canForward_ = canForward; }

  /**
   * Find or create the FIB entry with the given name and add the ForwarderFace
   * with the given faceId.
   * @param {Name} name The name of the FIB entry.
   * @param {integer} faceId The face ID of the face for the route.
   * @return {bool} True for success, or false if can't find the ForwarderFace
   * with faceId.
   */
  function registerRoute(name, faceId)
  {
    // Find the face with the faceId.
    local nexthopFace = null;
    for (local i = 0; i < faces_.len(); ++i) {
      if (faces_[i].faceId == faceId) {
        nexthopFace = faces_[i];
        break;
      }
    }

    if (nexthopFace == null)
      return false;

    // Check for a FIB entry for the name and add the face.
    for (local i = 0; i < FIB_.len(); ++i) {
      local fibEntry = FIB_[i];
      if (fibEntry.name.equals(name)) {
        // Make sure the face is not already added.
        if (fibEntry.faces.indexOf(nexthopFace) < 0)
          fibEntry.faces.push(nexthopFace);

        return true;
      }
    }

    // Make a new FIB entry.
    local fibEntry = FibEntry(name);
    fibEntry.faces.push(nexthopFace);
    FIB_.push(fibEntry);

    return true;
  }

  /**
   * Enable debug consoleLog statements.
   */
  function enableDebug() { debugEnable_ = true; }

  /**
   * Set the log level for consoleLog statements.
   * @param {integer} logLevel The log level value as follows. 0 (default) =
   * no logging. 1 = log information of incoming and outgoing Interest and Data
   * packets.
   */
  function setLogLevel(logLevel) { logLevel_ = logLevel; }

  /**
   * This is called by the listener when an entire TLV element is received.
   * If it is an Interest, look in the FIB for forwarding. If it is a Data packet,
   * look in the PIT to match an Interest.
   * @param {ForwarderFace} face The ForwarderFace with the transport that
   * received the element.
   * @param {Buffer} element The received element.
   */
  function onReceivedElement(face, element)
  {
    local interest = null;
    local data = null;
    // Use Buffer.get to avoid using the metamethod.
    if (element.get(0) == Tlv.Interest || element.get(0) == Tlv.Data) {
      local decoder = TlvDecoder(element);
      if (decoder.peekType(Tlv.Interest, element.len())) {
        interest = Interest();
        interest.wireDecode(element, TlvWireFormat.get());
      }
      else if (decoder.peekType(Tlv.Data, element.len())) {
        data = Data();
        data.wireDecode(element, TlvWireFormat.get());
      }
    }

    local nowSeconds = NdnCommon.getNowSeconds();
    // Remove timed-out PIT entries
    // Iterate backwards so we can remove the entry and keep iterating.
    for (local i = PIT_.len() - 1; i >= 0; --i) {
      if (nowSeconds >= PIT_[i].timeoutEndSeconds) {
        if (debugEnable_) {
          local entry = PIT_[i];
          consoleLog("<DBUG>LOG MicroForwarder: Timeout for Interest " +
            entry.interest.getName().toUri() + ", nonce " +
            entry.interest.getNonce().toHex() + ", lifetime " +
            entry.interest.getInterestLifetimeMilliseconds() + " ms on face " +
            entry.face.uri + "</DBUG>");
        }
        PIT_.remove(i);
      }
    }

    // Now process as Interest or Data.
    if (interest != null) {


      if (logLevel_ >= 1) {
	      if (face.uri == "internal://agent" || face.uri == "internal://app" ) 
	        consoleLog("<LOG>");
          consoleLog("<MFWD><INT>" + interest.getName().toUri() + "</INT><NONC>" + interest.getNonce().toHex() +
            "</NONC><FACE>" + face.uri + "</FACE>");
	      if (face.uri == "internal://agent") 
	        consoleLog("</LOG>");
      }
  

      if (localhostNamePrefix.match(interest.getName())) {
        // Ignore localhost.
        // Operant Logging 
        if (logLevel_ >= 1) consoleLog("</MFWD></LOG>");
        return;
      }

      // First check for a duplicate nonce on any face.
      for (local i = 0; i < PIT_.len(); ++i) {
        if (PIT_[i].interest.getNonce().equals(interest.getNonce())) {
          // Drop the duplicate nonce.
          if (logLevel_ >= 1)
      	    consoleLog("<DROP><INT> " +
		          interest.getName().toUri() + "</INT><NONC>" + interest.getNonce().toHex() +
		          "</NONC><FACE>" + face.uri + "</FACE></DROP>");
	        if (debugEnable_) consoleLog("<DBUG>LOG MicroForwarder: -> Dropping Interest with duplicate nonce</DBUG>");
          if (logLevel_ >= 1) consoleLog("<DBUG>LOG MicroForwarder: -> Dropping Interest with duplicate nonce</DBUG></MFWD></LOG>");
        return;
        }
      }

      // Check for a duplicate Interest.
      local timeoutEndSeconds;
      if (interest.getInterestLifetimeMilliseconds() != null)
        timeoutEndSeconds = nowSeconds + (interest.getInterestLifetimeMilliseconds() / 1000.0).tointeger();
      else
        // Use a default timeout.
        timeoutEndSeconds = nowSeconds + 4;

      for (local i = 0; i < PIT_.len(); ++i) {
        local entry = PIT_[i];
        // TODO: Check interest equality of appropriate selectors.
        if (entry.face == face &&
            entry.interest.getName().equals(interest.getName())) {
          // Duplicate PIT entry.
          if (debugEnable_)
            consoleLog("<DBUG>LOG MicroForwarder: -> Aggregating repeat Interest (not forwarding)" + "</DBUG>");
          // Update the interest timeout.
          if (timeoutEndSeconds > entry.timeoutEndSeconds)
            entry.timeoutEndSeconds = timeoutEndSeconds;
          return;
        }
      }

      // Add to the PIT.
      local pitEntry = PitEntry(interest, face, timeoutEndSeconds);
      PIT_.append(pitEntry);

      if (broadcastNamePrefix.match(interest.getName())) {
        // Special case: broadcast to all faces.
        for (local i = 0; i < faces_.len(); ++i) {
          local outFace = faces_[i];
          // Don't send the interest back to where it came from.
          if (outFace != face) {

            if (debugEnable_)
              consoleLog("<DBUG>LOG MicroForwarder: -> Sending Interest to broadcast face " +
                outFace.uri + "</DBUG>");

            outFace.sendBuffer(element);
          }
        }
      }

      else {
        // Send the interest to the faces in matching FIB entries.
        for (local i = 0; i < FIB_.len(); ++i) {
          local fibEntry = FIB_[i];

          // TODO: Need to check all for longest prefix match?
          if (fibEntry.name.match(interest.getName())) {
            for (local j = 0; j < fibEntry.faces.len(); ++j) {
              local outFace = fibEntry.faces[j];
              // If canForward_ is not defined, don't send the interest back to
              // where it came from.
              if (!(canForward_ == null && outFace == face)) {
                local canForwardResult = true;
                if (canForward_ != null)
                  // Note that canForward_  is called even if outFace == face.
                  canForwardResult = canForward_
                    (interest, face.faceId, face.uri, outFace.faceId outFace.uri,
                     fibEntry.name);

                if (canForwardResult == true) {
                  // Forward now.
                  if (debugEnable_)
                    consoleLog("<DBUG>" + face.uri + "</DBUG>");
                  if (logLevel_ >= 1)
		                if (face.uri == "internal://agent" && outFace.uri == "internal://app") consoleLog("<LOG><MFWD>");
                    consoleLog("<FACE>" + outFace.uri + "</FACE></MFWD>");
                outFace.sendBuffer(element);
                }

                else if (typeof canForwardResult == "float" && canForwardResult >= 0.0) {
                  // Forward after a delay.
                  if (debugEnable_)
                    consoleLog("<DBUG>LOG MicroForwarder: -> Sending Interest after " +
                      canForwardResult + " seconds delay to face " + outFace.uri + "</DBUG>");
                  if (logLevel_ >= 1)
                    consoleLog("</MFWD></LOG>");

                  imp.wakeup(canForwardResult, 
                             function() { outFace.sendBuffer(element); });
                }
              }
            }
          }
        }
      }
    }
    else if (data != null) {

      if ( logLevel_ >= 1 && face.uri != "internal://app" )
        consoleLog("<MFWD><DATA>" + data.getName().toUri() + "</DATA><FACE>" +
		      face.uri + "</FACE>");

      // Send the data packet to the face for each matching PIT entry.
      // Iterate backwards so we can remove the entry and keep iterating.
      local foundOne = false;
      for (local i = PIT_.len() - 1; i >= 0; --i) {
        local entry = PIT_[i];
        if (entry.face != null && entry.interest.matchesData(data)) {
	        foundOne = true;
          // Remove the entry before sending.
          PIT_.remove(i);

          if (logLevel_ >= 1)
            consoleLog("<FACE>" +
              entry.face.uri + "</FACE><INT>" +
              entry.interest.getName().toUri() + "</INT><NONCE>" +
              entry.interest.getNonce().toHex() + "</NONCE>");

          entry.face.sendBuffer(element);
          entry.face = null;
        }
      }
      if ( logLevel_ >= 1) {
	if (foundOne != true )
	  consoleLog("<DROP><DATA> " + data.getName().toUri() + "</DATA><FACE>" + face.uri + "</FACE></DROP>");
	consoleLog("</MFWD></LOG>");
      }
    }
  }

  /**
   * This is called when an object is received on a local face.
   * @param {ForwarderFace} face The ForwarderFace with the transport that
   * received the object.
   * @param {table} obj A Squirrel table where obj.type is a string.
   */
  function onReceivedObject(face, obj)
  {
    if (!(typeof obj == "table" && "type" in obj))
      return;

    if (obj.type == "rib/register") {
      local faceId;
      if ("faceId" in obj && obj.faceId != null)
        faceId = obj.faceId;
      else
        // Use the requesting face.
        faceId = face.faceId;

      if (!registerRoute(Name(obj.nameUri), faceId))
        // TODO: Send error reply?
        return;

      obj.statusCode <- 200;
      face.sendObject(obj);
    }
  }
}

// We use a global variable because static member variables are immutable.
MicroForwarder_instance <- null;

/**
 * A PitEntry is used in the PIT to record the face on which an Interest came 
 * in. (This is not to be confused with the entry object used by the application
 * library's PendingInterestTable class.)
 * @param {Interest} interest
 * @param {ForwarderFace} face
 */
class PitEntry {
  interest = null;
  face = null;
  timeoutEndSeconds = null;

  constructor(interest, face, timeoutEndSeconds)
  {
    this.interest = interest;
    this.face = face;
    this.timeoutEndSeconds = timeoutEndSeconds;
  }
}

/**
 * A FibEntry is used in the FIB to match a registered name with related faces.
 * @param {Name} name The registered name for this FIB entry.
 */
class FibEntry {
  name = null;
  faces = null; // array of ForwarderFace

  constructor (name)
  {
    this.name = name;
    this.faces = [];
  }
}

/**
 * A ForwarderFace is used by the faces list to represent a connection using the
 * given Transport.
 */
class ForwarderFace {
  uri = null;
  transport = null;
  faceId = null;

  /**
   * Create a ForwarderFace and set the faceId to a unique value.
   * @param {string} uri The URI to use in the faces/query and faces/list
   * commands.
   * @param {Transport} transport Communicate using the Transport object. You
   * must call transport.connect with an elementListener object whose
   * onReceivedElement(element) calls
   * microForwarder.onReceivedElement(face, element), with this face. If available
   * the transport's onReceivedObject(obj) should call
   * microForwarder.onReceivedObject(face, obj), with this face.
   */
  constructor(uri, transport)
  {
    this.uri = uri;
    this.transport = transport;
    this.faceId = ++ForwarderFace_lastFaceId;
  }

  /**
   * Check if this face is still enabled.
   * @returns {bool} True if this face is still enabled.
   */
  function isEnabled() { return transport != null; }

  /**
   * Disable this face so that isEnabled() returns false.
   */
  function disable() { transport = null; };

  /**
   * Send the object to the transport, if this face is still enabled.
   * @param {object} obj The object to send.
   */
  function sendObject(obj)
  {
    if (transport != null && "sendObject" in transport)
      transport.sendObject(obj);
  }

  /**
   * Send the buffer to the transport, if this face is still enabled.
   * @param {Buffer} buffer The bytes to send.
   */
  function sendBuffer(buffer)
  {
    if (this.transport != null)
      this.transport.send(buffer);
  }
}

ForwarderFace_lastFaceId <- 0;
/**                                                                            
 * Copyright (C) 2017 Operant Solar.
 * @author: Rama Nadendla <rama.nadendla@operantsolar.com>
 * This file is part of operant-base.
 * 
 *  operant-base is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  operant-base is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with operant-base.  If not, see <http://www.gnu.org/licenses/>.
 */

// Note: Debugging and Logging Enablers..
debugEnable <- true;
logEnable <- false;

class ImpUtilities {
    static function hexToInteger(hex)
    {
        local result = 0;
        local shift = hex.len() * 4;

        // For each digit..
        for(local i=0; i < hex.len(); i++)
        {
            local digit;

            // Convert from ASCII Hex to integer
            if(hex[i] >= 0x61)
                digit = hex[i] - 0x57;
            else if(hex[i] >= 0x41)
                 digit = hex[i] - 0x37;
            else
                 digit = hex[i] - 0x30;

            // Accumulate digit
            shift -= 4;
            result += digit << shift;
        }
        //consoleLog("result" + result);
        return result;
    }

    static function delay (startms, delayms) {
        while ((hardware.millis() - startms) < delayms) { imp.sleep(0.0010); }
    }

    static function hexConvert(val, len){
        return format("%." + (len*2) + "X", val)
    }

    static function hexToAscii(hex) {
        if (hex == null) return;
        if(hex.len() % 2 != 0) return;
        local retStr = ""
        for(local i = 0; i < hex.len()/2; i++) {
            retStr = retStr + format("%c", utilities.hexStringToInteger("0x" + hex.slice(i*2, (i*2)+2)));
        }
        return retStr;
    }
}
/**                                                                            
 * Copyright (C) 2017 Operant Solar.
 * @author: Rama Nadendla <rama.nadendla@operantsolar.com>
 * This file is part of operant-base.
 * 
 *  operant-base is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  operant-base is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with operant-base.  If not, see <http://www.gnu.org/licenses/>.
 */

/**
 * Make a global function to log a message to the console which works with
 * standard Squirrel or on the Imp.
 * @param {string} message The message to log.
 */
if (!("consoleLog" in getroottable()))
{
  consoleLog <- function(message)
  {
    if ("server" in getroottable())
      server.log(message);
    else
      print(message); print("\n");
  }
}

// Use hard-wired HMAC shared keys for testing. In a real application the signer
// ensures that the verifier knows the shared key and its keyName.
HMAC_KEY <- Blob(Buffer([
   0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15,
  16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31
]), false);

HMAC_KEY2 <- Blob(Buffer([
  32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47,
  48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63
]), false);

function onLoRaDataReceived() {
    if (debugEnable) {
//        consoleLog("<DBUG>OnDataReceived</DBUG>");
    }
    loRa_.read.call(loRa_);
}

class LoRa {
    inputBlob_ = null;
    loRaDriver_ = null;
	callbacks_ = null;
    msgID_ = "FEED";
    
    constructor () {
        // alias the LoRa serial port
        loRaDriver_ = hardware.uart0;
        // configure UART to callback when serial data arrives from LoRa radio
        loRaDriver_.configure(250000, 8, PARITY_NONE, 1, NO_CTSRTS, onLoRaDataReceived); // set to 250kbaud to match Atmel build of 3/5/17
    }

	/**
	 * This is called (usually by AsyncTransport.connect) to supply the callbacks
     * object which has the "onDataReceived" method which we call on receiving
	 * incoming data.
     * @params callbacks The callbacks object with the "onDataReceived" method.
     * (This is usually an AsyncTransport object.)
    */
	function setAsyncCallbacks(callbacks) { callbacks_ = callbacks; }
 
    /**
    * This is called by the MicroForwarder to send a packet.
    * @param {blob} value The bytes to send.
    */
    function write(value) {
        if (debugEnable) consoleLog("<DBUG>LoRa TX w/ #bytes = " + value.len() + "</DBUG>");
        send (value); 
    }

    function send(netMsg) {
        //follow the serial protocol for encoding content and broadcasting over loRa.
        //msgID_ + msg length + MAC address + msg + crc
        //delay transmission for 500ms.
        ImpUtilities.delay(hardware.millis(), 500);

        //blob to write to lora.
        local blobData = blob();
        blobData = writeBytes(msgID_, blobData);

	local msg = blob();
	msg.writestring(hardware.getdeviceid().slice(-6));
	msg.writeblob(netMsg);
        //write the length of data block to blobData
        //length is msg + crc (2bytes)
        blobData.writen(msg.len() + 2, 'w');

        //write data to send to blobData
        blobData.writeblob (msg);

        //crc is the id + length + msg NO CRC.
        local calculatedCRC = crc16(msg, msg.len()); //ImpUtilities.hexConvert(crc16(blobData, 2),2);
        //if (debugEnable) consoleLog("<DBUG>Crc: " + calculatedCRC + "</DBUG>");
        
        //write the CRC to the blobData
        blobData.writen(calculatedCRC, 'w');

        loRaDriver_.write(blobData);
        loRaDriver_.flush(); // wait until write done
        // Hid these logs to reduce log verbosity
	// if (debugEnable) {
        //  consoleLog("<DBUG>");
        //  consoleLog(blobData.tostring());
        //  consoleLog("</DBUG>");
	// }
    }

    function writeBytes(byteValue, blobData) {
        //strip any white space in the front or back.
        byteValue = strip(byteValue);

        // post error message, the cmd string needs to be even length.
        if (debugEnable && byteValue.len() % 2 != 0) {
            consoleLog("<DBUG>byte string length needs to be even.</DBUG>");
        }

        // we parse this into a blob containing the byte values of each pair of hex digits
        // and write that single byte value to the blob
        for (local i = 0 ; i < byteValue.len() ; i += 2) {
            // two characters in the hex string equal one value in the blob
            // turn a pair of hex characters into a single byte value
            local byteToWrite = ImpUtilities.hexToInteger(byteValue.slice(i, i+2));
            // write that byte value into the blob
            blobData.writen(byteToWrite, 'b');
        }
        return blobData;
    }

    // Parses the data received when loRa receives the hardware event.
    // loRaSerialBuffer is passed to several helper functions. Keep in
    // mind that each helper is marching the seek location of the blob
    // so the order of these calls is critical. Before chaning the order
    // ensure that it exactly matches the message specification.
    function read() {
    	local ts = hardware.millis();
        local loopCtr = 0;
        local loRaSerialBuffer = blob();
        local rByte = 0;

        if (debugEnable) {
           consoleLog("<DBUG>LoRa RX</DBUG>");
        }
        do {
            rByte = loRaDriver_.read();
            if (rByte != -1) {
                // don't store -1's indicating empty UART FIFO or 10, which is termination /N
                loRaSerialBuffer.writen (rByte, 'b');
                // reset the loop counter, we want to quit read loop when we've received N  -1's in a row with no data
                loopCtr = 0; 
            }
            loopCtr++;

        } while(loopCtr <= 100); // going to block here for 100 reads

        //flush to clear the buffers
        loRaDriver_.flush();

        // reset the pointer to the beginning
        loRaSerialBuffer.seek(0, 'b');

        // check for FE and ED consecutively
        if (isFeed(loRaSerialBuffer)) {
            processFeed(loRaSerialBuffer);
            return;
        }

        // check for DE and AF consecutively
        else if (isDeaf(loRaSerialBuffer)) {
            processDeaf(loRaSerialBuffer);
            return;
        }

        else {
            if (debugEnable) {
            consoleLog("<DBUG>Unrecognized LoRa msg</DBUG>");
            }
        }
    }  

    function processFeed(loRaSerialBuffer) {
        local byteCount = getByteCount(loRaSerialBuffer);
        if (byteCount == 0) return;

        local atmelMessage = getAtmelMessage(loRaSerialBuffer, byteCount); 
        if (isValidLoRaMessage(byteCount, loRaSerialBuffer, atmelMessage)) {
            local leader = atmelMessage.readstring(6);
            local blockAbleData = atmelMessage.readblob(byteCount - 8); //length net of	6 bytes of MAC and 2 bytes of CRC

            if (logEnable) {
                consoleLog("<LOG><LORA><RTIM>" + ts + "</RTIM><SENT>" + leader + "</SENT><BIN>");
                consoleLog(blockAbleData);
                consoleLog("</BIN></LORA>");
            }

            if(debugEnable) {
                consoleLog("<DBUG>FEED msg = ");
                consoleLog(blockAbleData);
                consoleLog("</DBUG>");
            }

            // Following is to ignore specific units to simulate out of range communication.
            if (true) {
                local myAddress = hardware.getdeviceid().slice(-6);
                local exclusionTable = { "56ddc8" : { "56ddb2" : true }, "56ddb2" : { "56ddc8" : true }, "572880" : { "57290e" : true }, "57290e" : { "572880" : true } };
                if ( myAddress in exclusionTable ) {
                    if (leader in exclusionTable[myAddress]) {
                        if (logEnable) consoleLog("<BLOK></BLOK></LORA></LOG>");
                        if(debugEnable) consoleLog("<DBUG>Blocking unit MAC = " + leader + "</DBUG>");
                        return;
                    }
                }
            }
			if (callbacks_ != null) {
				callbacks_.onDataReceived(blockAbleData);
			}
        }
    }

    function processDeaf(loRaSerialBuffer) {
        if (debugEnable) {
            consoleLog("<DBUG>DEAF msg</DBUG>");
        }    
    }

    function getAtmelMessage (loRaSerialBuffer, byteCount) {
        // Length at the time of write includes msg length + crc (2bytes)
        // subtracting 2 to get the actual msg.
        return loRaSerialBuffer.readblob(byteCount - 2);
    }

    /*
     * Check to see if this is a FEED 
     */
    function isFeed(loRaSerialBuffer) {
        // reset the pointer to the beginning
        loRaSerialBuffer.seek(0, 'b');

        if (loRaSerialBuffer.readn('b') != 0xFE) {
            return false;
        }

        if (loRaSerialBuffer.readn('b') != 0xED) {
            return false;
        }
        return true;
    }

    /*
     * Check to see if this is a DEAF 
     */
    function isDeaf(loRaSerialBuffer) {
        // reset the pointer to the beginning
        loRaSerialBuffer.seek(0, 'b');

        if (loRaSerialBuffer.readn('b') != 0xDE) {
            return false;
        }

        if (loRaSerialBuffer.readn('b') != 0xAF) {
            return false;
        }
        return true;
    }

    function getByteCount(loRaSerialBuffer) {
        local byteCount = loRaSerialBuffer.readn('w');
        if (byteCount == 0) {
            if (debugEnable) consoleLog("<DBUG>No payload</DBUG>");
        }
        return byteCount;
    }

    function isValidLoRaMessage (byteCount, loRaSerialBuffer, atmelMessage) {
        //read the CRC..
        try {
            local readCrc = loRaSerialBuffer.readn('w');
            if (readCrc != crc16(atmelMessage, byteCount - 2)) {
	            if (debugEnable) consoleLog("<DBUG>CRC error!</DBUG>");
                return false;
            }
        }
        catch(exception) {
	        if (debugEnable) consoleLog("<DBUG>LoRa packet error</DBUG>");
            return false;
        }
        return true;
    }

    //CrcInitialValue = 0x6604;
    CrcTable = [
    0x0000, 0xa2eb, 0xe73d, 0x45d6, 0x6c91, 0xce7a, 0x8bac, 0x2947,
    0xd922, 0x7bc9, 0x3e1f, 0x9cf4, 0xb5b3, 0x1758, 0x528e, 0xf065,
    0x10af, 0xb244, 0xf792, 0x5579, 0x7c3e, 0xded5, 0x9b03, 0x39e8,
    0xc98d, 0x6b66, 0x2eb0, 0x8c5b, 0xa51c, 0x07f7, 0x4221, 0xe0ca,
    0x215e, 0x83b5, 0xc663, 0x6488, 0x4dcf, 0xef24, 0xaaf2, 0x0819,
    0xf87c, 0x5a97, 0x1f41, 0xbdaa, 0x94ed, 0x3606, 0x73d0, 0xd13b,
    0x31f1, 0x931a, 0xd6cc, 0x7427, 0x5d60, 0xff8b, 0xba5d, 0x18b6,
    0xe8d3, 0x4a38, 0x0fee, 0xad05, 0x8442, 0x26a9, 0x637f, 0xc194,
    0x42bc, 0xe057, 0xa581, 0x076a, 0x2e2d, 0x8cc6, 0xc910, 0x6bfb,
    0x9b9e, 0x3975, 0x7ca3, 0xde48, 0xf70f, 0x55e4, 0x1032, 0xb2d9,
    0x5213, 0xf0f8, 0xb52e, 0x17c5, 0x3e82, 0x9c69, 0xd9bf, 0x7b54,
    0x8b31, 0x29da, 0x6c0c, 0xcee7, 0xe7a0, 0x454b, 0x009d, 0xa276,
    0x63e2, 0xc109, 0x84df, 0x2634, 0x0f73, 0xad98, 0xe84e, 0x4aa5,
    0xbac0, 0x182b, 0x5dfd, 0xff16, 0xd651, 0x74ba, 0x316c, 0x9387,
    0x734d, 0xd1a6, 0x9470, 0x369b, 0x1fdc, 0xbd37, 0xf8e1, 0x5a0a,
    0xaa6f, 0x0884, 0x4d52, 0xefb9, 0xc6fe, 0x6415, 0x21c3, 0x8328,
    0x8578, 0x2793, 0x6245, 0xc0ae, 0xe9e9, 0x4b02, 0x0ed4, 0xac3f,
    0x5c5a, 0xfeb1, 0xbb67, 0x198c, 0x30cb, 0x9220, 0xd7f6, 0x751d,
    0x95d7, 0x373c, 0x72ea, 0xd001, 0xf946, 0x5bad, 0x1e7b, 0xbc90,
    0x4cf5, 0xee1e, 0xabc8, 0x0923, 0x2064, 0x828f, 0xc759, 0x65b2,
    0xa426, 0x06cd, 0x431b, 0xe1f0, 0xc8b7, 0x6a5c, 0x2f8a, 0x8d61,
    0x7d04, 0xdfef, 0x9a39, 0x38d2, 0x1195, 0xb37e, 0xf6a8, 0x5443,
    0xb489, 0x1662, 0x53b4, 0xf15f, 0xd818, 0x7af3, 0x3f25, 0x9dce,
    0x6dab, 0xcf40, 0x8a96, 0x287d, 0x013a, 0xa3d1, 0xe607, 0x44ec,
    0xc7c4, 0x652f, 0x20f9, 0x8212, 0xab55, 0x09be, 0x4c68, 0xee83,
    0x1ee6, 0xbc0d, 0xf9db, 0x5b30, 0x7277, 0xd09c, 0x954a, 0x37a1,
    0xd76b, 0x7580, 0x3056, 0x92bd, 0xbbfa, 0x1911, 0x5cc7, 0xfe2c,
    0x0e49, 0xaca2, 0xe974, 0x4b9f, 0x62d8, 0xc033, 0x85e5, 0x270e,
    0xe69a, 0x4471, 0x01a7, 0xa34c, 0x8a0b, 0x28e0, 0x6d36, 0xcfdd,
    0x3fb8, 0x9d53, 0xd885, 0x7a6e, 0x5329, 0xf1c2, 0xb414, 0x16ff,
    0xf635, 0x54de, 0x1108, 0xb3e3, 0x9aa4, 0x384f, 0x7d99, 0xdf72,
    0x2f17, 0x8dfc, 0xc82a, 0x6ac1, 0x4386, 0xe16d, 0xa4bb, 0x0650];    

    function crc16(msg_blob,  msgLength){
        local nTemp;
        local wCRCWord = 0x6604;
        local nData = 0;
        local tableIndex = 0;
        while (msgLength--)    {
            tableIndex = (msg_blob[nData++] & 0xff) ^ ((wCRCWord >> 8) & 0xff);
            wCRCWord = ((wCRCWord << 8) ^ CrcTable[ tableIndex ]) & 0xffff;
        }
	if (0) {
	    if (debugEnable) consoleLog("<DBUG>crc16: Val " + wCRCWord + "</DBUG>");
	}
        return wCRCWord;
    }
}

//  -*- tab-width:4; indent-tabs-mode:nil;  -*-
/**                                                                            
 * (C) 2017 Operant Solar
 * All rights reserved
 *
 * @author: Rama Nadendla <rama.nadendla@operantsolar.com>
 * 
 */

/**
 * Make a global function to log a message to the console which works with
 * standard Squirrel or on the Imp.
 * @param {string} message The message to log.
 */
if (!("consoleLog" in getroottable()))
{
  consoleLog <- function(message)
  {
    if ("server" in getroottable())
      server.log(message);
    else
      print(message); print("\n");
  }
}

const auchCRCHi = "\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40\x00\xC1\x81\x40\x01\xC0\x80\x41\x00\xC1\x81\x40\x01\xC0\x80\x41\x01\xC0\x80\x41\x00\xC1\x81\x40";

// blob of CRC values for low–order byte
const auchCRCLo = "\x00\xC0\xC1\x01\xC3\x03\x02\xC2\xC6\x06\x07\xC7\x05\xC5\xC4\x04\xCC\x0C\x0D\xCD\x0F\xCF\xCE\x0E\x0A\xCA\xCB\x0B\xC9\x09\x08\xC8\xD8\x18\x19\xD9\x1B\xDB\xDA\x1A\x1E\xDE\xDF\x1F\xDD\x1D\x1C\xDC\x14\xD4\xD5\x15\xD7\x17\x16\xD6\xD2\x12\x13\xD3\x11\xD1\xD0\x10\xF0\x30\x31\xF1\x33\xF3\xF2\x32\x36\xF6\xF7\x37\xF5\x35\x34\xF4\x3C\xFC\xFD\x3D\xFF\x3F\x3E\xFE\xFA\x3A\x3B\xFB\x39\xF9\xF8\x38\x28\xE8\xE9\x29\xEB\x2B\x2A\xEA\xEE\x2E\x2F\xEF\x2D\xED\xEC\x2C\xE4\x24\x25\xE5\x27\xE7\xE6\x26\x22\xE2\xE3\x23\xE1\x21\x20\xE0\xA0\x60\x61\xA1\x63\xA3\xA2\x62\x66\xA6\xA7\x67\xA5\x65\x64\xA4\x6C\xAC\xAD\x6D\xAF\x6F\x6E\xAE\xAA\x6A\x6B\xAB\x69\xA9\xA8\x68\x78\xB8\xB9\x79\xBB\x7B\x7A\xBA\xBE\x7E\x7F\xBF\x7D\xBD\xBC\x7C\xB4\x74\x75\xB5\x77\xB7\xB6\x76\x72\xB2\xB3\x73\xB1\x71\x70\xB0\x50\x90\x91\x51\x93\x53\x52\x92\x96\x56\x57\x97\x55\x95\x94\x54\x9C\x5C\x5D\x9D\x5F\x9F\x9E\x5E\x5A\x9A\x9B\x5B\x99\x59\x58\x98\x88\x48\x49\x89\x4B\x8B\x8A\x4A\x4E\x8E\x8F\x4F\x8D\x4D\x4C\x8C\x44\x84\x85\x45\x87\x47\x46\x86\x82\x42\x43\x83\x41\x81\x80\x40";

class Modbus {
    _driver = null;
    _rtsPin = null;

    // this is the liength of time we will do the action reading on modbus (in ms)
    // may need to updated to a new number if it is longer.
    _readTimeLength = 100;
    _baudRate = 9600;

    constructor (baudRate=9600) {
        _baudRate= baudRate;
         if (debugEnable) consoleLog("<DBUG>Set Modbus Baud rate to: " + _baudRate + " </DBUG>");
        initialize();
    }

    function setReadTimeLnegth (timeLength) {
        _readTimeLength = timeLength;
    }

    // Initialize the modbus driver, configure the driver and the pin
    function initialize() {
        // Modbus Initialization
        //Alias the uart1
        _driver = hardware.uart1;
        //Configure the uart, leave it at 2400 baud rate to avoid issues.
        _driver.configure(_baudRate, 8, PARITY_NONE, 1, NO_CTSRTS );
        // Imp setup : Modbus hardware driver needs an RTS signal to set output enable
        _rtsPin = hardware.pinG;
        _rtsPin.configure(DIGITAL_OUT, 0);
    }

    // Write the included string to the Modbus, a character at a time
    function writeCommand(cmd) {
        //strip any white space in the front or back.
        cmd = strip(cmd);

        // post error message, the cmd string needs to be even length.
        if (cmd.len() % 2 != 0 && debugEnable ) consoleLog("<DBUG>Command string needs to even length</DBUG>");

        //set up a local blob for writing to UART
        local cmdBlob = blob();

        // we parse this into a blob containing the byte values of each pair of hex digits
        // and write that single byte value to the blob
        for (local i = 0 ; i < cmd.len() ; i += 2) {
            // two characters in the hex string equal one value in the blob
            // turn a pair of hex characters into a single byte value
            local byteValue = ImpUtilities.hexToInteger(cmd.slice(i, i+2));
            // write that byte value into the blob
            cmdBlob.writen(byteValue, 'b');
        }

        // Now we have the blob in writable format, send it to calculate the CRC
        // Calculated CRC16 in string form
        local calculatedCRC = ImpUtilities.hexConvert(CRC16(cmdBlob, 6),2);

        // need the Hi and Lo bytes in integer form to add to blob for output
        local crcHi = ImpUtilities.hexToInteger(calculatedCRC.slice(0,2));
        local crcLo = ImpUtilities.hexToInteger(calculatedCRC.slice(2,4));

        cmdBlob.writen(crcHi,'b');  // write that byte value into the blob
        cmdBlob.writen(crcLo,'b');  // write that byte value into the blob

        // Actually send to UART
        // raise RTS to enable the Modbus driver
        _rtsPin.write(1);
	if (debugEnable) {
	  consoleLog("<DBUG>");
	  consoleLog(cmdBlob);
	  consoleLog("</DBUG>");
	}
        _driver.flush();
        _driver.write(cmdBlob);
        // wait until write done to unassert RTS
        _driver.flush(); 
        // lower RTS to change back to receive mode for inverter reply
        _rtsPin.write(0); 
    }

    function baudRateToMicros() {
        return (1000000/_baudRate);
    }

    // Read data from UART FIFO
    function readResult() {

        local result = "";
        local byteVal = 0;
        // read failure timeout
        local readTimer = hardware.millis();
        local readWaitMicros = hardware.micros();
        local baudRateWait = baudRateToMicros();

         while ((hardware.millis() - readTimer) < _readTimeLength) {
            //wait for the hardware.micros() for atleast a bit period + margin
            //sleep for 10micros to avoid tight spin
            while (hardware.micros() < readWaitMicros + baudRateWait) {
                imp.sleep(0.000010);
            }

            byteVal = _driver.read();
            readWaitMicros = hardware.micros();

            // skip -1's indicates empty UART FIFO
            if (byteVal != -1 ) {
                result += format("%.2X",byteVal);
            }
            
        }
        if (result == ""){ 
            result = "01030400000000FA33";
            }
            
        if (debugEnable) consoleLog("<DBUG> Modbus result " + result + "</DBUG>");
        return  result;
    }

    // Example 2 - Translated from MODBUS over serial line specification and implementation
    // guide V1.02 (Appendix B)- C Implementation
    // http://modbus.com/docs/Modbus_over_serial_line_V1_02.pdf
    // This code uses a lookup table so should be faster but uses more memory
    // blob of CRC values for high–order byte

    function CRC16 ( puchMsg, usDataLen ){
        //unsigned char *puchMsg ; // message to calculate CRC upon
        //unsigned short usDataLen ; // quantity of bytes in message
        local uchCRCHi = 0xFF ; // high byte of CRC initialized
        local uchCRCLo = 0xFF ; // low byte of CRC initialized
        local uIndex ; // will index into CRC lookup table
        local i = 0;
        while (usDataLen--){ // pass through message buffer
            uIndex = uchCRCLo ^ puchMsg[i] ; // calculate the CRC
            uchCRCLo = uchCRCHi ^ auchCRCHi[uIndex] ;
            uchCRCHi = auchCRCLo[uIndex] ;
            i++
        }
        //return (uchCRCHi << 8 | uchCRCLo) ;
            return (uchCRCLo << 8 | uchCRCHi) ;
    }    
}
// Note: Name Slot definitions. Use this for indexing the Name. Avoid hardcoded index numbers
// as we may be changing these at will.
enum nameComponentIndex {
    fleetLink,
    usng,
    deviceIdHash,
    rw,
    category,
    task, // can't use the reserved word 'function'
    parameters
}

/* applicationBase
 * The purpose of this class is to handle the request body, parse it
 * and generate a NDN Name from the body. Agent would call this class
 * to fetch a name for the request body received.
 * Each application is required to extend this class and override the methods
 * for the Agent and Device to function as expected.
 */
class applicationBase {
    supportedNames_ = array();

    /*
     * Derived applications will add their supported names to the base collection of names
     * using this function
     */
    function addSupportedName(name) {
        supportedNames_.append(name);
    }

    /* 
     * Returns the collection of supported names of this application
     */
    function getSupportedNames() {
        return supportedNames_;
    }

    /*
    * Override this method to provide the Agent the wait time after which it would return an error
    */
    function getInterestLifetime() {
        return 12000;
    }

    /*
     * Override this method to return the array() of Name instances that your application is interested
     * processing. Note: each Name instance is a unique path..
     */
    function getNamesToRegister() {
        local nameColl = getSupportedNames();
        if (nameColl.len() == 0)
            addSupportedNames();
        return nameColl;
    }

    /*
     * Override this method and construct a new Name instance that is associated with the
     * http request body passed in.
     * Name: /usng/deviceIDHash//rw/category/function/parameters
     */
    function getNameforRequest(requestBody) {
        local name = Name ("/FL/");
        name.append(NameComponent(requestBody.usng));
        name.append(NameComponent(requestBody.deviceIdHash));
        name.append(NameComponent(requestBody.rw));
        name.append(NameComponent(requestBody.category));
        name.append(NameComponent(requestBody.task));
        name.append(NameComponent(requestBody.parameters));
        return name;
    }

    /*
     * Override this method and handle the incoming interest and return the result of handling the interest
     */
    function handleInterest (interest) {
        return "";
    }

    // Override this method and return the Device ID you wish to use as a NameComponent 
    function getDeviceIdExtract() {
        return "";
    }

    function getNamePrefix() {
        return "";
    }
    
    /*
     * Helper function that constructs a name given a path. Path is
     * separated by '|' for each NameComponent in the path.
     * internal|
     */
    function getNameforPath(path) {
        if(path == null) return null;

        local components = split(path, "|");
        if (components.len() == 0) return null;

        local name = Name(components[0]);
        for(local i = 1; i < components.len(); i++) {
            if (components[i] == " ")
                name.append(NameComponent(""));
            else
                name.append(NameComponent(components[i]));
        }
        return name;
    } 

    function getDeviceIdHash(manuf, model, serial) {
        //return getDeviceIdExtract();
        return getHashSha256(manuf+model+serial);
    }

    // Extract last 48bits of MAC address 
    function getDeviceIdExtract() {
        if (debugEnable)
            consoleLog("<DBUG> " + imp.getsoftwareversion() + "</DBUG>");
        return hardware.getdeviceid().slice(-6);
    }

    static function getHashSha256(text) {
        local blob = crypto.sha256(text);
        // seek to 6 bytes less than the end.
        blob.seek(-6, 'e');
        local result= "";
        for (local i = 0; i < 6 ; ++i) {
            result += format("%02X", blob.readn('b'));
        }        
        return result;
    }        
}

/**                                                                            
 * (C) 2017 Operant Solar
 * All rights reserved
 *
 * @author: Rama Nadendla <rama.nadendla@operantsolar.com>
 * 
 */

/* fleetLinkApplication
 * The purpose of this class is to handle the request body, parse it
 * and generate a NDN Name from the body. Handles the interests of this
 * Application, and returns the results for the supported names.
 */
class impApplication extends applicationBase {
    _usng = 28475668;

    /*
    * Base method override to provide the Agent the wait time after which it would return an error
    */
    function getInterestLifetime() {
        return 12000;
    }

    function getNamePrefix()
    {
        return "/FL/" + _usng + "/" + getDeviceIdHash("operant", "fleetLink", hardware.getdeviceid());
    }    

    /*
     * private method to add the NDN names that this application supports
     * Build Name: FL|usng|deviceIdHash|rw|category|function|parameters
     */
    function addSupportedNames() {
        local nameColl = getSupportedNames();
        local name = "";

        // fleetLink internal commands
        local deviceId = getDeviceIdHash("operant", "fleetLink", hardware.getdeviceid());
 
        name = getNameforPath("FL|28475668|" + deviceId + "|read|wiFi|scan");
        nameColl.append(name);
        
        name = getNameforPath("FL|28475668|" + deviceId + "|read|modbus|fc03");
        nameColl.append(name);

        // SunSpec commands
        deviceId = getDeviceIdHash("MeasurLogic", "DTS SKT2-92-NN-SM-N-2S-200", "DSKT201505001");
        name = getNameforPath("FL|28475668|" + deviceId + "|read|power|MC_AC_Power_A");
        nameColl.append(name);
    }

    function nameMatchesSupportedNames(name) {
        local nameColl = getSupportedNames();
        for(local i = 0; i < nameColl.len(); i++) {
            if (nameColl[i].match(name)) return true;
        }
        return false;
    }

    /*
     * Base method override that handles the incoming interest and returns the result of handling the interest
     */
    function handleInterest (interest) {
        local result = "";
        local name = interest.getName();

        //get the names that are registered.. we are not registering, but using them to
        //compare the name associated with the interest..
        local nameColl = getSupportedNames();
        if (nameColl.len() == 0) {
            addSupportedNames();
        }
        for(local i =0; i < nameColl.len(); i++) {
	    if (debugEnable) consoleLog("<DBUG>matching name " + nameColl[i] + " </DBUG>");
            // if we have a matching name
            if (nameColl[i].match(name)) {                
                //check to see if it is read or write
                if (name.get(nameComponentIndex.rw).toEscapedString() == "read") {
                    if (name.get(nameComponentIndex.category).toEscapedString() == "wiFi") {
                        result = scanWiFi(name.get(nameComponentIndex.task).toEscapedString(), name.get(nameComponentIndex.parameters).getValue().toRawStr());
                        break;
                    }
                    if (name.get(nameComponentIndex.category).toEscapedString() == "modbus") {
                        result = getmodbus(name.get(nameComponentIndex.task).toEscapedString(), name.get(nameComponentIndex.parameters).toEscapedString());
                        break;
                    }
                }
                
                else if (name.get(5).toEscapedString() == "write") {
                    if (name.get(3).toEscapedString() == "wiFi") {
                        //add code for writing something to WIFI
                        break;
                    }
                }
            }          
        }
        if (debugEnable) consoleLog("<DBUG> handleInterest result: " + result + "</DBUG>");
        return result;
    }

    /*
     * private method to handle the interest coming in the args. Appropriate
     * result associated with the args are returned if the contents of the
     * args match the supported entries.
     */
    function getmodbus(task, parameters) {
        local modbusCmd = getModbusCmd(task, parameters); // interest.getName().get(impNameElements.ModbusCmd).toEscapedString(); 
        if (debugEnable) consoleLog("<DBUG> Sending modbus cmd: " + modbusCmd + " </DBUG>");

        // Extract the Baud Rate from the parameters field and set Modbus driver accordingly
        // TODO: change Modbus constructor to take data and stop bits in similar fashion to Baud rate <<<<<<<<
        local requestedBaudRate = getModbusBaudRate(parameters);
        
        local modb = Modbus(requestedBaudRate);
        modb.writeCommand(modbusCmd);
        return modb.readResult();
    }

    // Construct the Modbus command form both Function and Parameters as required by standard
    function getModbusCmd (task, parameters) {
        local paramArray = split(parameters, "_");
        local modbusCmd = "";
        local i = 0;
        if (paramArray.len() >= 2) {
            modbusCmd += paramArray[0];
            modbusCmd += task.slice(2);
            modbusCmd += paramArray[1];
        }
        return modbusCmd;
    }

    // The requested Baud rate is the third component in the parameters field
    // Return as Integer
    function getModbusBaudRate (parameters) {
        local paramArray = split(parameters, "_");
        local modbusBaudRate = paramArray[2].tointeger();
        return modbusBaudRate;
    }

    /*
     * private method to handle the interest coming in the args. Appropriate
     * result associated with the args are returned if the contents of the
     * args match the supported entries.
     */
    function scanWiFi(task, parameters) {
        if (debugEnable) consoleLog("<DBUG>in getwifi, parameters = " + parameters + " </DBUG>")
        local requestedData = "";
        local wlans = imp.scanwifinetworks();
        local i = 1;
        
        if(task == "scan") {
            // If possible return only the specified network's SSID, RSSI. and channel 
            foreach (hotspot in wlans) {
                if(hotspot.ssid == parameters){
                    requestedData = hotspot.ssid;
                    requestedData += "|RSSI";
                    requestedData += format("%i", hotspot.rssi);
                    requestedData += "|Ch";
                    requestedData += hotspot.channel;
                }
            } 
            
            // If not specified or not found, return the SSID, RSSI. and channel for a random network
            if(requestedData == "") {     
                // Choose a network at random
                local numberNetworksFound = wlans.len();
                local networkIndex = (1.0 * math.rand() / RAND_MAX) * numberNetworksFound;
                networkIndex = networkIndex.tointeger();
                // if (debugEnable) consoleLog("<DBUG>Network " +  networkIndex + " chosen of " + numberNetworksFound + " found </DBUG>");
                requestedData = wlans[networkIndex].ssid;
                requestedData += "|RSSI";
                requestedData += format("%i", wlans[networkIndex].rssi);
                requestedData += "|Ch";
                requestedData += wlans[networkIndex].channel;
                requestedData += "|";
                requestedData += networkIndex + "of" + numberNetworksFound;
            }
        }

        return requestedData;
    } 
}
//operantsolar code from here


deviceApp_ <- impApplication();
contentKey_ <- null;
contentKeyName_ <- null;
contentKeyData_ <- null;

TEST_RSA_E_KEY <-
  "30819f300d06092a864886f70d010101050003818d0030818902818100c2d8db0d4f9acb99" +
  "36f678ac9b35a4448baf11755e593d660e12734af61c8127fde99ef1fedc3b15eaf0eb7122" +
  "3a3011f8dc7871af7dced81b53702c387e91ae0987a42d62a3c42fd1877eb05eb9fca77748" +
  "363c03d55f2481bce26bfc8b24fb8fc5b23e6286b20f82b439c13041b8b6230e0c0fa690bf" +
  "faf75db2be70bb96db0203010001";

/**
 * This is called by the library when an Interest is received. Make a Data
 * packet with the same name as the Interest, add a message content to the Data
 * packet and send it.
 * Note: Use this function to ALWAYS encrypt with AES.
 */
function onInterestWithAes(prefix, interest, face, interestFilterId, filter) {
  //initialize the contentKey_, contentKeyData_, contentKeyName_
  prepareContentForEncryption(face);

  if (debugEnable) consoleLog("<DBUG>contentKeyData " + contentKeyData_.getName()+ "</DBUG>");
  if (debugEnable) consoleLog("<DBUG>Interest with contentKeyData matches: " + interest.matchesData(contentKeyData_) + "</DBUG>");

  // returning the contentKeydata to the agent for decrypting the content.
  if (interest.matchesData(contentKeyData_)) {
    // This is a request for the Data packet with the contentKey.
    if (debugEnable) consoleLog("<DBUG>Sending contentKeyData " + contentKeyData_.getName()+ "</DBUG>");
    face.putData(contentKeyData_);
    return;
  }

  if (deviceApp_.nameMatchesSupportedNames(interest.getName())) {
    local data = Data(interest.getName());
    local content = deviceApp_.handleInterest(interest);
    // Encrypt with AesCbc and an auto-generated initialization vector.
    Encryptor.encryptData
      (data, Blob(content), contentKeyName_, contentKey_, EncryptParams(EncryptAlgorithmType.AesCbc, 16));
  
    // For now, add a fake signature.
    data.getSignature().getKeyLocator().setType(KeyLocatorType.KEYNAME);
    data.getSignature().getKeyLocator().setKeyName(Name("key1"));

    if (debugEnable) consoleLog("<DBUG>Sending content " + content + "</DBUG>");
    face.putData(data);
  }
}

/**
 * This is called by the library when an Interest is received. Make a Data
 * packet with the same name as the Interest, add a message content to the Data
 * packet and send it.
 */
function onInterestTestVectors(prefix, interest, face, interestFilterId, filter) {
  if (contentKey_ == null) {
    // Generate the contentKey and encrypt it with the recipient's E-KEY to make
    // the contentKeyData packet which is meant for the recipient's D-KEY.
    //contentKey_ = AesAlgorithm.generateKey(AesKeyParams(128)).getKeyBits();
    contentKey_ = DecryptKey(Blob([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])).getKeyBits();
    if(debugEnable) consoleLog("<DBUG>AES content key= " + contentKey_.toHex() +"</DBUG>");
    contentKeyName_ = Name("/testecho/C-KEY/1");
  }

  local data = Data(interest.getName());
  //local content = deviceApp_.handleInterest(interest);
  local content = blob();
  for (local i = 0; i < 16; i++) {
    if (i == 0) content.writen(0x80, 'b');
    content.writen(0, 'b');
  }

  // Encrypt with AesCbc and an auto-generated initialization vector.
  local encryptParams = EncryptParams(EncryptAlgorithmType.AesCbc);
  encryptParams.setInitialVector(Blob([0, 0, 0, 0, 0, 0, 0, 0,
                                       0, 0, 0, 0, 0, 0, 0, 0]));
  Encryptor.encryptData
    (data, Blob(content), contentKeyName_, contentKey_, encryptParams);
  
  //data.setContent(content);
  
  // Dump the correct encrypted value, which is surrounded by
  // meta info to help the consumer identify the decryption key. We can extract:
  if (debugEnable) {
    local encryptedContent = EncryptedContent();
    encryptedContent.wireDecode(data.getContent());
    consoleLog("<DBUG>Encrypted payload " + encryptedContent.getPayload().toHex() + "</DBUG>");
    // Jeff T: Note that the NIST test vectors are for fixed 16-byte block sizes.
    // But applications have variable content size, so encryptData pads the data.
    // This means that there is an extra block of 16 bytes at the end of the
    // expected vector. We can make life easier and just show the first 16-byte block:
    consoleLog("<DBUG>Payload 1st block " +
      Blob(encryptedContent.getPayload().buf().slice(0, 16)).toHex() + "</DBUG>");
  }

  // For now, add a fake signature.
  //data.setSignature(HmacWithSha256Signature());
  data.getSignature().getKeyLocator().setType(KeyLocatorType.KEYNAME);
  data.getSignature().getKeyLocator().setKeyName(Name("key1"));
  //KeyChain.signWithHmacWithSha256(data, HMAC_KEY);
  face.putData(data);
}

/**
 * This is called by the library when an Interest is received. Make a Data
 * packet with the same name as the Interest, add a message content to the Data
 * packet and send it.
 * Note: Function does not do ANY encryption.
 */
function onInterest(prefix, interest, face, interestFilterId, filter) {
  local data = Data(interest.getName());
  local content = deviceApp_.handleInterest(interest);
  data.setContent(content);
  
  // For now, add a fake signature.
  data.getSignature().getKeyLocator().setType(KeyLocatorType.KEYNAME);
  data.getSignature().getKeyLocator().setKeyName(Name("/key/name"));

  if (debugEnable)
    consoleLog("<DBUG>Sending content " + content + "</DBUG>");
  face.putData(data);
}

// LoRa instance for the device
loRa_ <- LoRa();

/* 
 * This function prepares the contentKey_, contentKeyData_, contentKeyName_ 
 * for encryption that is done in onInterest
 */
 function prepareContentForEncryption(face) {
  if (contentKey_ == null) {
    // Generate the contentKey and encrypt it with the recipient's E-KEY to make
    // the contentKeyData packet which is meant for the recipient's D-KEY.

    contentKey_ = AesAlgorithm.generateKey(AesKeyParams(128)).getKeyBits();
    contentKeyName_ = Name(deviceApp_.getNamePrefix() + "/C-KEY/1");
    //face.registerPrefixUsingObject(contentKeyName_);
    

    contentKeyData_ = Data(contentKeyName_);
    Encryptor.encryptData
      (contentKeyData_, contentKey_, Name(deviceApp_.getNamePrefix()+"/D-KEY/1"),
       Blob(Buffer(TEST_RSA_E_KEY, "hex"), false), EncryptParams(EncryptAlgorithmType.RsaPkcs));

    // Use the signature object in the data object to avoid an extra copy.
    contentKeyData_.getSignature().getKeyLocator().setType(KeyLocatorType.KEYNAME);
    contentKeyData_.getSignature().getKeyLocator().setKeyName(Name("key1"));

    if (debugEnable) consoleLog("<DBUG> Generated contentKeyData " + contentKeyData_.getName().toUri() + "</DBUG>");
  }
 }


/**
 * Create a MicroForwarder with a route to the agent. Then create an application
 * Face which automatically connects to the MicroForwarder. Register to receive
 * Interests and call onInterest which sends a reply Data packet. You should run
 * this on the Imp Device, and run test-imp-echo-consumer.agent.nut on the Agent.
 */
function deviceMain() {
  if (logEnable) {
    consoleLog("<LOG><DEVH><DVID>" + hardware.getdeviceid() + "</DVID></DEVH></LOG>");
    MicroForwarder.get().setLogLevel(0);
  }
  if (debugEnable) MicroForwarder.get().enableDebug();
  MicroForwarder.get().addFace
    ("internal://agent", SquirrelObjectTransport(),
     SquirrelObjectTransportConnectionInfo(agent));

  local asyncTransport = AsyncTransport();
  local loRaFaceId = MicroForwarder.get().addFace
    ("uart://LoRa", asyncTransport, AsyncTransportConnectionInfo(loRa_));
   MicroForwarder.get().registerRoute(Name("/"), loRaFaceId)

   // Face for local device.
  local face = Face();
  
  local names = deviceApp_.getNamesToRegister();
  // Register the application prefix.
  face.registerPrefixUsingObject(Name(deviceApp_.getNamePrefix()));

  for (local i = 0 ; i < names.len() ; ++i) {
    local prefix = names[i];
    if (debugEnable)
      consoleLog("<DBUG>Register prefix " + prefix.toUri() + "</DBUG>");
    //The interest is for this device, and its handler is onInterest().
    // NOTE: Change the onInterest function name appropriately to either onInterest, onInterestWithAes or onInterestTestVectors to 
    // modify what we are testing.
    face.setInterestFilter(prefix.toUri(), onInterest);
  } 
  // Don't change the following onInterestWithAes reference!
  face.setInterestFilter(Name(deviceApp_.getNamePrefix() + "/C-KEY/1").toUri(), onInterestWithAes);

  // Set this to true to use multi-hop Interest forwarding, as opposed to single-hop.
  local useMultiHop = true;
  // Set the min and max values for the random delay.
  local minDelaySeconds = 0.5;
  local maxDelaySeconds = 0.69;

  function hasPrefixOf(name) {
    for (local i = 0 ; i < names.len() ; ++i) {
        local prefix = names[i];
        if (prefix.isPrefixOf(name))
          return true;
    }
    return false; 
  }

  // Set up the forwarding strategy for single-hop or multi-hop broadcast
  // (depending on useMultiHop).
  function canForward (interest, incomingFaceId, incomingFaceUri, outgoingFaceId, outgoingFaceUri,
     routePrefix) {
    local isForwardingToSameFace = (incomingFaceId == outgoingFaceId);

    if (incomingFaceUri == "uart://LoRa") {
      // Coming from the serial port.
      if (hasPrefixOf(interest.getName())) {
        // The Interest is for the application, so let it go to the application
        // but don't forward to other faces.
        if (outgoingFaceUri == "internal://app")
          return true;
        else
          return false;
      }
      else {
        if (useMultiHop) {
          // For multi-hop, we only forward to the same broadcast serial port
          // (after a delay).
          if (outgoingFaceUri != "uart://LoRa")
            return false;
          else {
            // Forward with a delay.
            local delayRange = maxDelaySeconds - minDelaySeconds;
            local delaySeconds = minDelaySeconds + 
              ((1.0 * math.rand() / RAND_MAX) * delayRange);
            // Return a float value that the MicroForwarder interprets as a delay.
            return delaySeconds;
          }
        }
        else
          // For single-hop, we don't forward packets coming in the serial port.
          return false;
      }
    }

    if (incomingFaceUri == "internal://agent") {
      // Coming from the Agent.
      if (hasPrefixOf(interest.getName())) {
        // The Interest is for the application, so let it go to the application
        // but don't forward to other faces.
        if (outgoingFaceUri == "internal://app")
          return true;
        else
          return false;
      }
      else
        // Not for the application, so forward to other faces including serial,
        // except don't forward to the same face.
        return !isForwardingToSameFace;
    }

    // Let other packets pass, except to the same face.
    return !isForwardingToSameFace;
  }
  MicroForwarder.get().setCanForward(canForward);  
}

deviceMain();
