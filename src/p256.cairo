# Implementation of the ECDSA signature verification over the secp256r1 elliptic curve.
# See information on the curve in p256_def.cairo.
#
# The generator point for the ECDSA is:
#   G = (
#       0x6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296,
#       0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8
#   )

from bigint import BASE, BigInt3, bigint_mul,nondet_bigint3
from p256_def import N0, N1, N2
from p256_ec import EcPoint, ec_add, ec_mul

from starkware.cairo.common.math import assert_nn_le, assert_not_zero

# Computes x * s^(-1) modulo the size of the elliptic curve (N).
func mul_s_inv{range_check_ptr}(x : BigInt3, s : BigInt3, N : BigInt3) -> (res : BigInt3):
    
    %{
        from starkware.cairo.common.cairo_secp.secp_utils import pack
        from starkware.python.math_utils import div_mod, safe_div

        n = pack(ids.N, PRIME)
        x = pack(ids.x, PRIME) % n
        s = pack(ids.s, PRIME) % n
        value = res = div_mod(x, s, n)
    %}
    let (res) = nondet_bigint3()

    %{ value = k = safe_div(res * s - x, n) %}
    let (k) = nondet_bigint3()

    let (res_s) = bigint_mul(res, s)
    
    let (k_n) = bigint_mul(k, N)

    # We should now have res_s = k_n + x. Since the numbers are in unreduced form,
    # we should handle the carry.

    tempvar carry1 = (res_s.d0 - k_n.d0 - x.d0) / BASE
    assert [range_check_ptr + 0] = carry1 + 2 ** 127

    tempvar carry2 = (res_s.d1 - k_n.d1 - x.d1 + carry1) / BASE
    assert [range_check_ptr + 1] = carry2 + 2 ** 127

    tempvar carry3 = (res_s.d2 - k_n.d2 - x.d2 + carry2) / BASE
    assert [range_check_ptr + 2] = carry3 + 2 ** 127

    tempvar carry4 = (res_s.d3 - k_n.d3 + carry3) / BASE
    assert [range_check_ptr + 3] = carry4 + 2 ** 127

    assert res_s.d4 - k_n.d4 + carry4 = 0

    let range_check_ptr = range_check_ptr + 4

    return (res=res)
end

# Verifies that val is in the range [1, N).
func validate_signature_entry{range_check_ptr}(val : BigInt3):
    assert_nn_le(val.d2, N2)
    assert_nn_le(val.d1, BASE - 1)
    assert_nn_le(val.d0, BASE - 1)

    if val.d2 == N2:
        if val.d1 == N1:
            assert_nn_le(val.d0, N0 - 1)
            return ()
        end
        assert_nn_le(val.d1, N1 - 1)
        return ()
    end

    if val.d2 == 0:
        if val.d1 == 0:
            # Make sure val > 0.
            assert_not_zero(val.d0)
            return ()
        end
    end
    return ()
end

# Verifies a Secp256R1 ECDSA signature.
# Soundness assumptions:
# * public_key_pt is on the curve.
# * All the limbs of public_key_pt.x, public_key_pt.y, msg_hash are in the range [0, 3 * BASE).
func verify_ecdsa{range_check_ptr}(
        public_key_pt : EcPoint, msg_hash : BigInt3, r : BigInt3, s : BigInt3):
    alloc_locals
    
    validate_signature_entry(r)
    validate_signature_entry(s)

    let gen_pt = EcPoint(
        BigInt3(0x2b33a0f4a13945d898c296, 0x1b958e9103c9dc0df604b7, 0x6b17d1f2e12c4247f8bce),
        BigInt3(0x315ececbb6406837bf51f5, 0x2d29f03e7858af38cd5dac, 0x4fe342e2fe1a7f9b8ee7e))
    
    let N = BigInt3(N0, N1, N2)
    # Compute u1 and u2.
    let (u1 : BigInt3) = mul_s_inv(msg_hash, s, N)
    let (u2 : BigInt3) = mul_s_inv(r, s, N)

    let (gen_u1) = ec_mul(gen_pt, u1)
    let (pub_u2) = ec_mul(public_key_pt, u2)
    let (res) = ec_add(gen_u1, pub_u2)
    
    # The following assert also implies that res is not the zero point.
    assert res.x = r
    
    return ()
end
