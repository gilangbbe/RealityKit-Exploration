import simd

@inline(__always)
func length_squared(_ v: SIMD3<Float>) -> Float {
    return simd_length_squared(v)
}
