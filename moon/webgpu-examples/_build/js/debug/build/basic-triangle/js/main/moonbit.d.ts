/**
 * A non-public unique symbol used to mark the brand of a type.
 * And avoid user to construct values of the type.
 */
export const __brand: unique symbol;

export type Unit = undefined;
export type Bool = boolean;

/**
 * A signed integer in 32-bit two's complement format.
 */
export type Int = number;

/**
 * An unsigned integer in 32-bit two's complement format.
 */
export type UInt = number;

/**
 * A character in the range 0-0x10FFFF.
 */
export type Char = number;

/**
 * A byte in the range 0-255.
 */
export type Byte = number;

/**
 * Single-precision floating point number.
 */
export type Float = number;

export type Double = number;

/**
 * Backed by `bigint`, but not equal to the backing value:
 * runtime operations interpret it with signed 64-bit wraparound semantics.
 * Use `BigInt.asIntN(64, x)` to get the numerically equivalent `bigint`.
 */
export type Int64 = bigint & { [__brand]: "Int64" };

/**
 * Backed directly by `bigint`.
 * Valid `UInt64` values are in the unsigned 64-bit range `[0, 2^64)`.
 */
export type UInt64 = bigint & { [__brand]: "UInt64" };

export type String = string;

export type Bytes = Uint8Array;

export type FixedArray<T> = T[];

export type UnboxedOption<T> = /* Some */ T | /* None */ undefined;

export type UnboxedOptionAsInt<T> = /* Some */ T | /* None */ -1;

export type Result<T, E> =
  | /* Ok */ { $tag: 1; _0: T }
  | /* Err */ { $tag: 0; _0: E };
