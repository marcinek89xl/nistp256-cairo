# The base of the representation.
const BASE = 2 ** 64

# Represents an integer defined by
#   d0 + BASE * d1 + BASE**2 * d2 + BASE**3 * d3.
# Note that d0, d1, d2, d3 must be in the range [0, BASE).
# In most cases this is used to represent a secp256r1 field element.
struct BigInt4:
    # The first 64 bits of the value
    member d0: felt
    # The second 64 bits of the value
    member d1: felt
    # The third 64 bits of the value
    member d2: felt
    # The forth 64 bits of the value
    member d3: felt
end

func bigint_zero() -> (res: BigInt4):
    return (
        BigInt4(
        d0=0,
        d1=0,
        d2=0,
        d3=0,
        ))
end

# R = 2^256 mod p
func bigint_one() -> (res: BigInt4):
    return (
        BigInt4(
        d0=0x0000000000000001,
        d1=0xffffffff00000000,
        d2=0xffffffffffffffff,
        d3=0x00000000fffffffe,
    ))
end

# Constant representing the modulus
# p = 2^{224}(2^{32} − 1) + 2^{192} + 2^{96} − 1
func bigint_MODULUS() -> (res: BigInt4):
    return (
        BigInt4(
        d0=0xffffffffffffffff,
        d1=0x00000000ffffffff,
        d2=0x0000000000000000,
        d3=0xffffffff00000001,
        ))
end

# b = 0x5AC635D8AA3A93E7B3EBBD55769886BC651D06B0CC53B0F63BCE3C3E27D2604B
func CURVE_EQUATION_B() -> (res:BigInt4):
    return (
        BigInt4(
        d0=0xd89cdf6229c4bddf,
        d1=0xacf005cd78843090,
        d2=0xe5a220abf7212ed6,
        d3=0xdc30061d04874834
        )
    )
end

func CURVE_ORDER_N() -> (BigInt4):
    return (
        BigInt4(
        d0=0xF3B9CAC2FC632551,
        d1=0xBCE6FAADA7179E84,
        d2=0xFFFFFFFFFFFFFFFF,
        d3=0xFFFFFFFF00000000
        )
    )
end

func out_bigInt4{output_ptr}(a: BigInt4):
    let output = cast(output_ptr, BigInt4*)
    assert [output] = a
    let output_ptr = output_ptr + BigInt4.SIZE
    return ()
end