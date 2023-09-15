////
//// Copyright 2017 Christian Reitwiessner
//// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
////
//// 2019 OKIMS
////      ported to solidity 0.6
////      fixed linter warnings
////      added requiere error messages
////
////
//// SPDX-License-Identifier: GPL-3.0
//pragma solidity ^0.8.0;
//
//library Pairing {
//    struct G1Point {
//        uint X;
//        uint Y;
//    }
//    // Encoding of field elements is: X[0] * z + X[1]
//    struct G2Point {
//        uint[2] X;
//        uint[2] Y;
//    }
//    struct FQ12 {
//        uint256[12] memory coeffs;
//    }
//
//    // Define addition for FQ12
//    function addFQ12(FQ12 memory a, FQ12 memory b) internal view returns (FQ12 memory) {
//        FQ12 memory result;
//        for (uint8 i = 0; i < a.degree; i++) {
//            result.coeffs[i] = a.coeffs[i] + b.coeffs[i];
//        }
//        return result;
//    }
//
//    // Define subtraction for FQ12
//    function subFQ12(FQ12 memory a, FQ12 memory b) internal view returns (FQ12 memory) {
//        FQ12 memory result;
//        for (uint8 i = 0; i < a.degree; i++) {
//            result.coeffs[i] = a.coeffs[i] - b.coeffs[i];
//        }
//        return result;
//    }
//
//    // Define multiplication for FQ12
//    function mulFQ12(FQ12 memory a, FQ12 memory b) internal view returns (FQ12 memory) {
//        FQ12 memory result;
//        uint256[23] memory bCoeffsExtended;
//        for (uint8 i = 0; i < a.degree; i++) {
//            for (uint8 j = 0; j < b.degree; j++) {
//                bCoeffsExtended[i + j] += a.coeffs[i] * b.coeffs[j];
//            }
//        }
//        for (uint8 i = 0; i < a.degree; i++) {
//            result.coeffs[i] = bCoeffsExtended[i];
//        }
//        return result;
//    }
//
//    // Define division for FQ12
//    function divFQ12(FQ12 storage a, FQ12 storage b) internal view returns (FQ12 memory) {
//        FQ12 memory result;
//        FQ12 memory bInverse = invFQ12(b);
//        result = mulFQ12(a, bInverse);
//        return result;
//    }
//
//    // Define modular exponentiation for FQ12
//    function powFQ12(FQ12 storage a, uint256 exponent) internal view returns (FQ12 memory) {
//        FQ12 memory result = FQ12one();
//        FQ12 memory base = a;
//        while (exponent > 0) {
//            if (exponent & 1 == 1) {
//                result = mulFQ12(result, base);
//            }
//            base = mulFQ12(base, base);
//            exponent >>= 1;
//        }
//        return result;
//    }
//
//    // Define modular inverse for FQ12
//    function invFQ12(FQ12 storage a) internal view returns (FQ12 memory) {
//        FQ12 memory lm = FQ12one();
//        FQ12 memory hm;
//        hm.degree = a.degree + 1;
//        uint256[13] memory low = a.coeffs;
//        uint256[13] memory high = a.modulusCoeffs;
//
//        while (degFQ12(low) > 0) {
//            uint256[13] memory r = polyRoundedDiv(high, low);
//            uint256[13] memory nm;
//            uint256[13] memory newHigh;
//            for (uint8 i = 0; i < hm.degree; i++) {
//                nm[i] = lm.coeffs[i];
//                newHigh[i] = high[i];
//            }
//            for (uint8 i = 0; i <= a.degree; i++) {
//                for (uint8 j = 0; j <= a.degree - i; j++) {
//                    nm[i + j] -= lm.coeffs[i] * r[j];
//                    newHigh[i + j] -= low[i] * r[j];
//                }
//            }
//            lm = FQ12(nm);
//            low = newHigh;
//        }
//        return div(lm, FQ12([low[0]]));
//    }
//
//    // Define a function to calculate the degree of the polynomial
//    function degFQ12(uint256[13] memory poly) internal pure returns (uint8) {
//        for (uint8 i = 12; i > 0; i--) {
//            if (poly[i] != 0) {
//                return i;
//            }
//        }
//        return 0;
//    }
//
//    // Define a function to perform polynomial division with rounding
//    function polyRoundedDiv(uint256[13] memory high, uint256[13] memory low) internal pure returns (uint256[13] memory) {
//        uint8 exp = uint8(12 - deg(high) - deg(low));
//        uint256 top = high[deg(high)];
//        for (uint8 i = 0; i <= 12 - deg(low); i++) {
//            high[exp + i] -= top * low[deg(low) + i];
//        }
//        return high;
//    }
//
//    // Define a function to create an FQ12 with all coefficients set to 0
//    function FQ12zero() internal pure returns (FQ12 memory) {
//        FQ12 memory zero;
//        zero.degree = 12;
//        return zero;
//    }
//
//    // Define a function to create an FQ12 with all coefficients set to 1
//    function FQ12one() internal pure returns (FQ12 memory) {
//        FQ12 memory one;
//        one.degree = 12;
//        for (uint8 i = 0; i < 12; i++) {
//            one.coeffs[i] = 1;
//        }
//        return one;
//    }
//
//    /*
////    function add(FQ12 memory a, FQ12 memory b) internal pure returns (FQ12 memory) {
////        require(a.degree == b.degree, "Degrees must match");
////        uint8 degree = a.degree;
////        uint256[] memory resultCoeffs = new uint256[](degree);
////
////        for (uint8 i = 0; i < degree; i++) {
////            resultCoeffs[i] = a.coeffs[i] + b.coeffs[i];
////        }
////
////        return FQ12(resultCoeffs, a.modulus_coeffs, degree);
////    }
////
////    function sub(FQ12 memory a, FQ12 memory b) internal pure returns (FQ12 memory) {
////        require(a.degree == b.degree, "Degrees must match");
////        uint8 degree = a.degree;
////        uint256[] memory resultCoeffs = new uint256[](degree);
////
////        for (uint8 i = 0; i < degree; i++) {
////            resultCoeffs[i] = a.coeffs[i] - b.coeffs[i];
////        }
////
////        return FQ12(resultCoeffs, a.modulus_coeffs, degree);
////    }
////
////    function mul(FQ12 memory a, FQ12 memory b) internal pure returns (FQ12 memory) {
////        require(a.degree == b.degree, "Degrees must match");
////        uint8 degree = a.degree;
////        uint256[] memory resultCoeffs = new uint256[](degree * 2 - 1);
////
////        for (uint8 i = 0; i < degree; i++) {
////            for (uint8 j = 0; j < degree; j++) {
////                resultCoeffs[i + j] += a.coeffs[i] * b.coeffs[j];
////            }
////        }
////
////        while (resultCoeffs.length > degree) {
////            uint256 exp = resultCoeffs.length - degree - 1;
////            uint256 top = resultCoeffs[resultCoeffs.length - 1];
////
////            for (uint8 k = 0; k < degree; k++) {
////                resultCoeffs[exp + k] -= top * a.modulus_coeffs[k];
////            }
////
////            resultCoeffs.pop();
////        }
////
////        return FQ12(resultCoeffs, a.modulus_coeffs, degree);
////    }
////
////    function mulFQScalar(FQ12 memory a, uint256 scalar) internal pure returns (FQ12 memory) {
////        uint8 degree = a.degree;
////        uint256[] memory resultCoeffs = new uint256[](degree);
////
////        for (uint8 i = 0; i < degree; i++) {
////            resultCoeffs[i] = a.coeffs[i] * scalar;
////        }
////
////        return FQ12(resultCoeffs, a.modulus_coeffs, degree);
////    }
////
////    function div(FQ12 memory a, FQ12 memory b) internal pure returns (FQ12 memory) {
////        require(a.degree == b.degree, "Degrees must match");
////        uint8 degree = a.degree;
////        uint256[] memory resultCoeffs = new uint256[](degree);
////
////        for (uint8 i = 0; i < degree; i++) {
////            resultCoeffs[i] = a.coeffs[i] / b.coeffs[i];
////        }
////
////        return FQ12(resultCoeffs, a.modulus_coeffs, degree);
////    }
////
////    function pow(FQ12 memory base, uint256 exponent) internal pure returns (FQ12 memory) {
////        if (exponent == 0) {
////            uint8 degree = base.degree;
////            uint256[] memory oneCoeffs = new uint256[](degree);
////            oneCoeffs[0] = 1;
////            return FQ12(oneCoeffs, base.modulus_coeffs, degree);
////        } else if (exponent == 1) {
////            return base;
////        } else if (exponent % 2 == 0) {
////            FQ12 memory square = mulFQ(base, base);
////            return powFQ(square, exponent / 2);
////        } else {
////            FQ12 memory square = mulFQ(base, base);
////            return mulFQ(powFQ(square, exponent / 2), base);
////        }
////    }
//
////    function inv(FQ12 memory a) internal pure returns (FQ12 memory) {
////        uint8 degree = a.degree;
////        uint256[] memory lm = new uint256[](degree + 1);
////        uint256[] memory hm = new uint256[](degree + 1);
////        uint256[] memory low = new uint256[](degree + 1);
////        uint256[] memory high = new uint256[](degree + 1);
////
////        lm[0] = 1;
////        hm[degree] = 1;
////
////        for (uint8 i = 0; i < degree; i++) {
////            low[i] = a.coeffs[i];
////            high[i] = a.modulus_coeffs[i];
////        }
////
////        while (low.length > 0) {
////            (uint256[] memory r, uint256 exp) = polyRoundedDiv(high, low);
////            uint256[] memory nm = new uint256[](degree + 1);
////            uint256[] memory newHigh = new uint256[](degree + 1);
////
////            for (uint8 i = 0; i < degree + 1; i++) {
////                for (uint8 j = 0; j < degree + 1 - i; j++) {
////                    nm[i + j] -= lm[i] * r[j];
////                    newHigh[i + j] -= low[i] * r[j];
////                }
////            }
////
////            lm = nm;
////            low = newHigh;
////            (lm, low) = polyNormalize(lm, low);
////        }
////
////        return FQ12(lm, a.modulus_coeffs, degree).divFQ(low[0]);
////    }
////
////    function polyNormalize(uint256[] memory a, uint256[] memory b) internal pure returns (uint256[] memory, uint256[] memory) {
////        uint8 degree = uint8(a.length) - 1;
////        uint8 leadingCoeff = degree;
////        while (leadingCoeff > 0 && a[leadingCoeff] == 0) {
////            leadingCoeff--;
////        }
////        uint256[] memory resultA = new uint256[](leadingCoeff + 1);
////        uint256[] memory resultB = new uint256[](leadingCoeff + 1);
////        for (uint8 i = 0; i < leadingCoeff + 1; i++) {
////            resultA[i] = a[i];
////            resultB[i] = b[i];
////        }
////        return (resultA, resultB);
////    }
////
////    function polyRoundedDiv(uint256[] memory a, uint256[] memory b) internal pure returns (uint256[] memory, uint256) {
////        uint8 degreeA = uint8(a.length) - 1;
////        uint8 degreeB = uint8(b.length) - 1;
////        require(degreeB <= degreeA, "Division degree error");
////
////        uint256[] memory quotient = new uint256[](degreeA - degreeB + 1);
////        uint256[] memory remainder = new uint256[](degreeA + 1);
////
////        for (uint8 i = 0; i <= degreeA; i++) {
////            remainder[i] = a[i];
////        }
////
////        for (uint8 i = degreeA - degreeB; i >= 0; i--) {
////            uint256 coef = remainder[degreeA - i] / b[degreeB];
////            quotient[i] = coef;
////
////            for (uint8 j = 0; j <= degreeB; j++) {
////                remainder[i + j] -= coef * b[j];
////            }
////        }
////
////        return (quotient, remainder[0]);
////    }
//    */
//    function powFQ12(FQ12 memory base, uint256 exponent) internal pure returns (FQ12 memory) {
//        if (exponent == 0) {
//            uint256[12] memory oneCoeffs;
//            oneCoeffs[0] = 1;
//            return FQ12(oneCoeffs);
//        } else if (exponent == 1) {
//            return base;
//        } else if (exponent % 2 == 0) {
//            FQ12 memory square = mulFQ12(base, base);
//            return powFQ12(square, exponent / 2);
//        } else {
//            FQ12 memory square = mulFQ12(base, base);
//            return mulFQ12(powFQ12(square, exponent / 2), base);
//        }
//    }
//
//    function mulFQ12(FQ12 memory a, FQ12 memory b) internal pure returns (FQ12 memory) {
//        uint256[12] memory resultCoeffs;
//
//        resultCoeffs[0] = a.coeffs[0] * b.coeffs[0] - a.coeffs[1] * b.coeffs[1] + a.coeffs[2] * b.coeffs[10] - a.coeffs[3] * b.coeffs[11] + a.coeffs[4] * b.coeffs[8] - a.coeffs[5] * b.coeffs[9] + a.coeffs[6] * b.coeffs[6] - a.coeffs[7] * b.coeffs[7] + a.coeffs[8] * b.coeffs[4] - a.coeffs[9] * b.coeffs[5] + a.coeffs[10] * b.coeffs[2] - a.coeffs[11] * b.coeffs[3];
//        resultCoeffs[1] = a.coeffs[0] * b.coeffs[1] + a.coeffs[1] * b.coeffs[0] + a.coeffs[2] * b.coeffs[11] + a.coeffs[3] * b.coeffs[10] + a.coeffs[4] * b.coeffs[9] + a.coeffs[5] * b.coeffs[8] + a.coeffs[6] * b.coeffs[7] + a.coeffs[7] * b.coeffs[6] + a.coeffs[8] * b.coeffs[5] + a.coeffs[9] * b.coeffs[4] + a.coeffs[10] * b.coeffs[3] + a.coeffs[11] * b.coeffs[2];
//        resultCoeffs[2] = a.coeffs[0] * b.coeffs[2] - a.coeffs[1] * b.coeffs[3] + a.coeffs[2] * b.coeffs[0] - a.coeffs[3] * b.coeffs[1] + a.coeffs[4] * b.coeffs[10] + a.coeffs[5] * b.coeffs[11] + a.coeffs[6] * b.coeffs[4] - a.coeffs[7] * b.coeffs[5] + a.coeffs[8] * b.coeffs[6] - a.coeffs[9] * b.coeffs[7] + a.coeffs[10] * b.coeffs[8] - a.coeffs[11] * b.coeffs[9];
//        resultCoeffs[3] = a.coeffs[0] * b.coeffs[3] + a.coeffs[1] * b.coeffs[2] + a.coeffs[2] * b.coeffs[1] + a.coeffs[3] * b.coeffs[0] + a.coeffs[4] * b.coeffs[11] - a.coeffs[5] * b.coeffs[10] + a.coeffs[6] * b.coeffs[5] + a.coeffs[7] * b.coeffs[4] + a.coeffs[8] * b.coeffs[7] + a.coeffs[9] * b.coeffs[6] + a.coeffs[10] * b.coeffs[9] + a.coeffs[11] * b.coeffs[8];
//        resultCoeffs[4] = a.coeffs[0] * b.coeffs[4] - a.coeffs[1] * b.coeffs[5] + a.coeffs[2] * b.coeffs[10] + a.coeffs[3] * b.coeffs[11] + a.coeffs[4] * b.coeffs[0] + a.coeffs[5] * b.coeffs[1] + a.coeffs[6] * b.coeffs[2] + a.coeffs[7] * b.coeffs[3] + a.coeffs[8] * b.coeffs[8] - a.coeffs[9] * b.coeffs[9] + a.coeffs[10] * b.coeffs[6] - a.coeffs[11] * b.coeffs[7];
//        resultCoeffs[5] = a.coeffs[0] * b.coeffs[5] + a.coeffs[1] * b.coeffs[4] - a.coeffs[2] * b.coeffs[9] + a.coeffs[3] * b.coeffs[8] - a.coeffs[4] * b.coeffs[1] + a.coeffs[5] * b.coeffs[0] - a.coeffs[6] * b.coeffs[3] + a.coeffs[7] * b.coeffs[2] - a.coeffs[8] * b.coeffs[9] - a.coeffs[9] * b.coeffs[8] + a.coeffs[10] * b.coeffs[7] + a.coeffs[11] * b.coeffs[6];
//        resultCoeffs[6] = a.coeffs[0] * b.coeffs[6] - a.coeffs[1] * b.coeffs[7] - a.coeffs[2] * b.coeffs[4] - a.coeffs[3] * b.coeffs[5] + a.coeffs[4] * b.coeffs[2] - a.coeffs[5] * b.coeffs[3] - a.coeffs[6] * b.coeffs[0] + a.coeffs[7] * b.coeffs[1] - a.coeffs[8] * b.coeffs[10] - a.coeffs[9] * b.coeffs[11] + a.coeffs[10] * b.coeffs[8] + a.coeffs[11] * b.coeffs[9];
//        resultCoeffs[7] = a.coeffs[0] * b.coeffs[7] + a.coeffs[1] * b.coeffs[6] + a.coeffs[2] * b.coeffs[5] - a.coeffs[3] * b.coeffs[4] + a.coeffs[4] * b.coeffs[3] + a.coeffs[5] * b.coeffs[2] - a.coeffs[6] * b.coeffs[1] - a.coeffs[7] * b.coeffs[0] - a.coeffs[8] * b.coeffs[11] + a.coeffs[9] * b.coeffs[10] + a.coeffs[10] * b.coeffs[11] - a.coeffs[11] * b.coeffs[10];
//        resultCoeffs[8] = a.coeffs[0] * b.coeffs[8] - a.coeffs[1] * b.coeffs[9] + a.coeffs[2] * b.coeffs[6] - a.coeffs[3] * b.coeffs[7] - a.coeffs[4] * b.coeffs[10] - a.coeffs[5] * b.coeffs[11] + a.coeffs[6] * b.coeffs[4] + a.coeffs[7] * b.coeffs[5] + a.coeffs[8] * b.coeffs[0] + a.coeffs[9] * b.coeffs[1] - a.coeffs[10] * b.coeffs[2] + a.coeffs[11] * b.coeffs[3];
//        resultCoeffs[9] = a.coeffs[0] * b.coeffs[9] + a.coeffs[1] * b.coeffs[8] + a.coeffs[2] * b.coeffs[7] + a.coeffs[3] * b.coeffs[6] - a.coeffs[4] * b.coeffs[11] + a.coeffs[5] * b.coeffs[10] - a.coeffs[6] * b.coeffs[5] - a.coeffs[7] * b.coeffs[4] + a.coeffs[8] * b.coeffs[1] - a.coeffs[9] * b.coeffs[0] - a.coeffs[10] * b.coeffs[3] - a.coeffs[11] * b.coeffs[2];
//        resultCoeffs[10] = a.coeffs[0] * b.coeffs[10] + a.coeffs[1] * b.coeffs[11] - a.coeffs[2] * b.coeffs[8] - a.coeffs[3] * b.coeffs[9] - a.coeffs[4] * b.coeffs[4] - a.coeffs[5] * b.coeffs[5] - a.coeffs[6] * b.coeffs[2] - a.coeffs[7] * b.coeffs[3] - a.coeffs[8] * b.coeffs[2] + a.coeffs[9] * b.coeffs[3] + a.coeffs[10] * b.coeffs[0] + a.coeffs[11] * b.coeffs[1];
//        resultCoeffs[11] = a.coeffs[0] * b.coeffs[11] - a.coeffs[1] * b.coeffs[10] + a.coeffs[2] * b.coeffs[9] - a.coeffs[3] * b.coeffs[8] - a.coeffs[4] * b.coeffs[5] + a.coeffs[5] * b.coeffs[4] - a.coeffs[6] * b.coeffs[3] + a.coeffs[7] * b.coeffs[2] + a.coeffs[8] * b.coeffs[3] - a.coeffs[9] * b.coeffs[2] + a.coeffs[10] * b.coeffs[1] - a.coeffs[11] * b.coeffs[0];
//
//        return FQ12(resultCoeffs);
//    }
////    function invFQ12(FQ12 memory a) internal pure returns (FQ12 memory) {
////        uint8 degree = 12;
////        uint256[] memory lm = new uint256[](degree + 1);
////        uint256[] memory hm = new uint256[](degree + 1);
////        uint256[] memory low = new uint256[](degree + 1);
////        uint256[] memory high = new uint256[](degree + 1);
////
////        lm[0] = 1;
////        hm[degree] = 1;
////
////        for (uint8 i = 0; i < degree; i++) {
////            low[i] = a.coeffs[i];
////            high[i] = a.modulus_coeffs[i];
////        }
////
////        while (low.length > 0) {
////            (uint256[] memory r, uint256 exp) = polyRoundedDiv(high, low);
////            uint256[] memory nm = new uint256[](degree + 1);
////            uint256[] memory newHigh = new uint256[](degree + 1);
////
////            for (uint8 i = 0; i < degree + 1; i++) {
////                for (uint8 j = 0; j < degree + 1 - i; j++) {
////                    nm[i + j] -= lm[i] * r[j];
////                    newHigh[i + j] -= low[i] * r[j];
////                }
////            }
////
////            lm = nm;
////            low = newHigh;
////            (lm, low) = polyNormalize(lm, low);
////        }
////
////        return FQ12(lm).divFQ(low[0]);
////    }
////    function divFQ12(FQ12 memory a, FQ12 memory b) internal pure returns (FQ12 memory) {
////        return mulFQ12(a, invFQ12(b));
////    }
//    function isZeroFQ12(FQ12 memory a) internal pure returns (bool) {
//        for (uint8 i = 0; i < 12; i++) {
//            if (a.coeffs[i] != 0) {
//                return false;
//            }
//        }
//        return true;
//    }
//    function isOneFQ12(FQ12 memory a) internal pure returns (bool) {
//        return a.coeffs[0] == 1 && isZeroFQ12(FQ12({
//            coeffs: [a.coeffs[1], a.coeffs[2], a.coeffs[3], a.coeffs[4], a.coeffs[5], a.coeffs[6], a.coeffs[7], a.coeffs[8], a.coeffs[9], a.coeffs[10], a.coeffs[11]],
//            // modulus_coeffs: a.modulus_coeffs,
//            degree: a.degree
//        }));
//    }
//
//    /// @return the generator of G1
//    function P1() internal pure returns (G1Point memory) {
//        return G1Point(1, 2);
//    }
//    /// @return the generator of G2
//    function P2() internal pure returns (G2Point memory) {
//        // Original code point
//        return G2Point(
//            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
//             10857046999023057135944570762232829481370756359578518086990519993285655852781],
//            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
//             8495653923123431417604973247489272438418190587263600148770280649306958101930]
//        );
//
///*
//        // Changed by Jordi point
//        return G2Point(
//            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
//             11559732032986387107991004021392285783925812861821192530917403151452391805634],
//            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
//             4082367875863433681332203403145435568316851327593401208105741076214120093531]
//        );
//*/
//    }
//    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
//    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
//        // The prime q in the base field F_q for G1
//        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
//        if (p.X == 0 && p.Y == 0)
//            return G1Point(0, 0);
//        return G1Point(p.X, q - (p.Y % q));
//    }
//
//    function double(G1Point memory pt) internal pure returns (G1Point memory result) {
//
//        uint256 x = pt.X;
//        uint256 y = pt.Y;
//
//        uint256 m = 3 * x**2 / (2 * y);
//        uint256 newX = m**2 - 2 * x;
//        uint256 newY = -m * newX + m * x - y;
//
////        uint256 l = mulmod(mulmod(3, mulmod(x, x, P), inverse(mulmod(2, y, P))), inverse(y), P);
////        uint256 newX = mulmod(l, l, P) - mulmod(2, x, P);
////        uint256 newY = mulmod(l, (newX - x), P) - y;
//        return G1Point(newX, newY);
//    }
//
//    /// @return r the sum of two points of G1
//    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
//        uint256 x1 = p1.X;
//        uint256 y1 = p1.Y;
//        uint256 x2 = p2.X;
//        uint256 y2 = p2.Y;
//
//        if (x1 == x2 && y1 == y2) {
//            return double(p1);
//        } else if (x1 == x2) {
//            return G1Point(0, 0); // Return the point at infinity (None in Python)
//        }
//
//        uint256 l = (y2 - y1) * inverse(x2 - x1);
//        uint256 newX = mulmod(l, l, P) - x1 - x2;
//        uint256 newY = mulmod(l, (newX - x1), P) - y1;
//        assert(newY == mulmod(l, (newX - x2), P) - y2);
//
//        return G1Point(newX, newY);
//
////        uint[4] memory input;
////        input[0] = p1.X;
////        input[1] = p1.Y;
////        input[2] = p2.X;
////        input[3] = p2.Y;
////        bool success;
////        // solium-disable-next-line security/no-inline-assembly
////        assembly {
////            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
////            // Use "invalid" to make gas estimation work
////            switch success case 0 { invalid() }
////        }
////        require(success,"pairing-add-failed");
//    }
//    /// @return r the product of a point on G1 and a scalar, i.e.
//    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
//    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
//        G1Point memory result = G1Point(0, 0);
//        G1Point memory current = p;
//
//        for (uint256 i = 0; i < 256; i++) {
//            if ((s >> i) & 1 == 1) {
//                result = addition(result, current);
//            }
//            current = double(current);
//        }
//
//        return result;
//
////        uint[3] memory input;
////        input[0] = p.X;
////        input[1] = p.Y;
////        input[2] = s;
////        bool success;
////        // solium-disable-next-line security/no-inline-assembly
////        assembly {
////            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
////            // Use "invalid" to make gas estimation work
////            switch success case 0 { invalid() }
////        }
////        require (success,"pairing-mul-failed");
//    }
//
//    // 检查点是否为无穷远点（点在椭圆曲线上无穷远点的情况）
//    function isInfinity(G1Point memory pt) internal pure returns (bool) {
//        return pt.X == 0 && pt.Y == 0;
//    }
//    function isInfinityG2(G2Point memory pt) internal pure returns (bool) {
//        return pt.X[0] == 0 && pt.Y[0] == 0 && pt.X[1] == 0 && pt.Y[1] == 0;
//    }
//
//    // 检查点是否位于椭圆曲线上的函数
//    function isOnCurve(G1Point memory pt, uint256 b) internal pure returns (bool) {
//        if (isInfinity(pt)) return true;
//        uint256 x = pt.X;
//        uint256 y = pt.Y;
//        return y * y == x * x * x + b;
//    }
//    // Cast a point to FQ12
//    function castPointToFQ12(G1Point memory pt) internal pure returns (FQ12 memory, FQ12 memory) {
//        if (isInfinity(pt)) {
//            return FQ12([0]); // Return a "zero" FQ12 point
//        }
//
//        FQ12 memory fq12X = FQ12([pt.X, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
//        FQ12 memory fq12Y = FQ12([pt.Y, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
//
//        return (fq12X, fq12Y);
//    }
//
//    // Twist a point
//    function twist(G2Point memory pt) internal pure returns (FQ12 memory, FQ12 memory) {
//        if (isInfinityG2(pt)) {
//            return G2Point(0, 0); // Return the point at infinity
//        }
//
//        uint256 _x1 = pt.X[0];
//        uint256 _y1 = pt.Y[0];
//        uint256 _x2 = pt.X[1];
//        uint256 _y2 = pt.Y[1];
//
//        // Field isomorphism from Z[p] / x^2 to Z[p] / x^2 - 18*x + 82
//        uint256[2] memory xCoeffs = [_x1 - _x2 * 9, _x2];
//        uint256[2] memory yCoeffs = [_y1 - _y2 * 9, _y2];
//
//        FQ12 memory w = FQ12([0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
//
//        // Isomorphism into subfield of Z[p] / w^12 - 18 * w^6 + 82
//        FQ12 memory nx = FQ12([xCoeffs[0], 0, 0, 0, 0, 0, xCoeffs[1], 0, 0, 0, 0, 0]);
//        FQ12 memory ny = FQ12([yCoeffs[0], 0, 0, 0, 0, 0, yCoeffs[1], 0, 0, 0, 0, 0]);
//
//        // Divide x coord by w^2 and y coord by w^3
//        return (mulFQ12(nx, powFQ12(w, 2)), mulFQ12(ny, powFQ12(w, 3)));
//    }
//
//    // Import necessary libraries and define the Point2D and Field types appropriately
//    // Define the linefunc function
//    function linefunc(FQ12[] memory P1, FQ12[] memory P2, FQ12[] memory T) internal pure returns (FQ12 memory) {
//        // Check if P1, P2, and T are not points at infinity
//        require(P1[0] != 0 || P1[1] != 0, "P1 cannot be point at infinity");
//        require(P2[0] != 0 || P2[1] != 0, "P2 cannot be point at infinity");
//        require(T[0] != 0 || T[1] != 0, "T cannot be point at infinity");
//
//        // Declare variables for coordinates
//        FQ12 memory x1 = P1[0];
//        FQ12 memory y1 = P1[1];
//        FQ12 memory x2 = P2[0];
//        FQ12 memory y2 = P2[1];
//        FQ12 memory xt = T[0];
//        FQ12 memory yt = T[1];
//
//        if (x1 != x2) {
//            // Calculate slope m
//            FQ12 memory m = (y2 - y1) / (x2 - x1);
//            // Calculate the result
//            return m * (xt - x1) - (yt - y1);
//        } else if (y1 == y2) {
//            // Calculate slope m
//            FQ12 memory m = (3 * x1 * x1) / (2 * y1);
//            // Calculate the result
//            FQ12 memory result = m * (xt - x1) - (yt - y1);
//            return result;
//        } else {
//            // Calculate the result
//            FQ12 memory result = xt - x1;
//            return result;
//        }
//    }
//
//    // Main miller loop
//    function millerLoop(FQ12 memory QX, FQ12 memory QY, FQ12 memory PX, FQ12 memory PY) internal pure returns (FQ12 memory) {
//        FQ12 memory RX = QX;
//        FQ12 memory RY = QY;
//        FQ12 memory f = FQ12([1]);
//
////        ate_loop_count = 29793968203157093288
////        log_ate_loop_count = 63
//        uint256 ate_loop_count = 29793968203157093288;
//        uint256 log_ate_loop_count = 63;
//
//        for (int256 i = log_ate_loop_count; i >= 0; i--) {
//            f = mulFQ12(f, mulFQ12(f, linefunc(R, R, P)));
//            RX = double(RX);
//
//            if ((ate_loop_count & (2**uint256(i))) != 0) {
//                f = mulFQ12(f, linefunc(R, Q, P));
//                R = addition(R, Q);
//            }
//        }
//
//        uint256 field_modulus = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
//
////        field_modulus = 21888242871839275222246405745257275088696311157297823662689037894645226208583
//        Q = G1Point(Q.X ** field_modulus, Q.Y ** field_modulus);
//        G1Point memory nQ2 = G1Point(Q.X ** field_modulus, field_modulus - Q.Y ** field_modulus);
//
//        f = mulFQ12(f, linefunc(R, Q, P));
//        R = addition(R, Q);
//        f = mulFQ12(f, linefunc(R, nQ2, P));
//
//        return powFQ12(f, (field_modulus**12 - 1) / curve_order);
//    }
//
//    // Pairing computation
//    function pairingE(G2Point memory Q, G1Point memory P) public pure returns (FQ12 memory) {
//        if (isInfinityG2(Q) || isInfinity(P)) {
//            return FQ12([1]); // Return FQ12.one()
//        }
//
//        FQ12 memory twistedQX;
//        FQ12 memory twistedQY;
//        FQ12 memory fq12PX;
//        FQ12 memory fq12PY;
//
//        (twistedQX, twistedQY) = twist(Q);
//        (fq12PX, fq12PY) = castPointToFQ12(P);
//
//        return millerLoop(twistedQ, fq12P);
//    }
//
//    /// @return the result of computing the pairing check
//    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
//    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
//    /// return true.
//    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
//        require(p1.length == p2.length,"pairing-lengths-failed");
//
//
////        uint elements = p1.length;
////        uint inputSize = elements * 6;
////        uint[] memory input = new uint[](inputSize);
////        for (uint i = 0; i < elements; i++)
////        {
////            input[i * 6 + 0] = p1[i].X;
////            input[i * 6 + 1] = p1[i].Y;
////            input[i * 6 + 2] = p2[i].X[0];
////            input[i * 6 + 3] = p2[i].X[1];
////            input[i * 6 + 4] = p2[i].Y[0];
////            input[i * 6 + 5] = p2[i].Y[1];
////        }
////        uint[1] memory out;
////        bool success;
////        // solium-disable-next-line security/no-inline-assembly
////        assembly {
////            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
////            // Use "invalid" to make gas estimation work
////            switch success case 0 { invalid() }
////        }
////        require(success,"pairing-opcode-failed");
////        return out[0] != 0;
//    }
//    /// Convenience method for a pairing check for two pairs.
//    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
//        G1Point[] memory p1 = new G1Point[](2);
//        G2Point[] memory p2 = new G2Point[](2);
//        p1[0] = a1;
//        p1[1] = b1;
//        p2[0] = a2;
//        p2[1] = b2;
//        return pairing(p1, p2);
//    }
//    /// Convenience method for a pairing check for three pairs.
//    function pairingProd3(
//            G1Point memory a1, G2Point memory a2,
//            G1Point memory b1, G2Point memory b2,
//            G1Point memory c1, G2Point memory c2
//    ) internal view returns (bool) {
//        G1Point[] memory p1 = new G1Point[](3);
//        G2Point[] memory p2 = new G2Point[](3);
//        p1[0] = a1;
//        p1[1] = b1;
//        p1[2] = c1;
//        p2[0] = a2;
//        p2[1] = b2;
//        p2[2] = c2;
//        return pairing(p1, p2);
//    }
//    /// Convenience method for a pairing check for four pairs.
//    function pairingProd4(
//            G1Point memory a1, G2Point memory a2,
//            G1Point memory b1, G2Point memory b2,
//            G1Point memory c1, G2Point memory c2,
//            G1Point memory d1, G2Point memory d2
//    ) internal view returns (bool) {
//        G1Point[] memory p1 = new G1Point[](4);
//        G2Point[] memory p2 = new G2Point[](4);
//        p1[0] = a1;
//        p1[1] = b1;
//        p1[2] = c1;
//        p1[3] = d1;
//        p2[0] = a2;
//        p2[1] = b2;
//        p2[2] = c2;
//        p2[3] = d2;
//        return pairing(p1, p2);
//    }
//}
//contract HydraS1Verifier {
//    using Pairing for *;
//    struct VerifyingKey {
//        Pairing.G1Point alfa1;
//        Pairing.G2Point beta2;
//        Pairing.G2Point gamma2;
//        Pairing.G2Point delta2;
//        Pairing.G1Point[] IC;
//    }
//    struct Proof {
//        Pairing.G1Point A;
//        Pairing.G2Point B;
//        Pairing.G1Point C;
//    }
//    function verifyingKey() public pure returns (VerifyingKey memory vk) {
//        vk.alfa1 = Pairing.G1Point(
//            20491192805390485299153009773594534940189261866228447918068658471970481763042,
//            9383485363053290200918347156157836566562967994039712273449902621266178545958
//        );
//
//        vk.beta2 = Pairing.G2Point(
//            [4252822878758300859123897981450591353533073413197771768651442665752259397132,
//             6375614351688725206403948262868962793625744043794305715222011528459656738731],
//            [21847035105528745403288232691147584728191162732299865338377159692350059136679,
//             10505242626370262277552901082094356697409835680220590971873171140371331206856]
//        );
//        vk.gamma2 = Pairing.G2Point(
//            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
//             10857046999023057135944570762232829481370756359578518086990519993285655852781],
//            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
//             8495653923123431417604973247489272438418190587263600148770280649306958101930]
//        );
//        vk.delta2 = Pairing.G2Point(
//            [12386877986471385655593194274339858982949258909999797978538617302099560728865,
//             12124297972012968925863647070786369342070521724147389547593290934893564311573],
//            [18045897098667004007805205602139049771362297381703603590858769390835925641784,
//             11770472181409854685114930487063987084873305288445817341533232114704725168760]
//        );
//        vk.IC = new Pairing.G1Point[](6);
//
//        vk.IC[0] = Pairing.G1Point(
//            16844725402348282092534707921707798397424122938642060915032182706860297337335,
//            20328375526671794080594392985809829627364180683931692830785236380728478819701
//        );
//
//        vk.IC[1] = Pairing.G1Point(
//            17657115390633025635244585110443757761774425536409336048414205080721801594099,
//            18859841292693379600214481025000184652308112726813546344732257789027347903100
//        );
//
//        vk.IC[2] = Pairing.G1Point(
//            3268410440059116079942370416056976125301307558308319527257923271570223608459,
//            18466946985444088282980126131750154325333495981535144400614814562568000413664
//        );
//
//        vk.IC[3] = Pairing.G1Point(
//            20343562477030088593147001008308397585185885600952052562001361467564055823446,
//            10982963249777938008233833016278660272454905281701443149436569271300903277673
//        );
//
//        vk.IC[4] = Pairing.G1Point(
//            19194933981187854315360551247066760957960025708987183804922656717712771178600,
//            11406420560988168977716927632317840483592567960149761483733823677678655797093
//        );
//
//        vk.IC[5] = Pairing.G1Point(
//            12093074084439936608734373567906499127238996069650366827976506688113426860991,
//            8304971305978646704309539167308624123307946367166801273081477187358017972040
//        );
//
//    }
//    function verify(uint[] memory input, Proof memory proof) public view returns (uint) {
//        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
//        VerifyingKey memory vk = verifyingKey();
//        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
//        // Compute the linear combination vk_x
//        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
//        for (uint i = 0; i < input.length; i++) {
//            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
//            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
//        }
//        vk_x = Pairing.addition(vk_x, vk.IC[0]);
//        if (!Pairing.pairingProd4(
//            Pairing.negate(proof.A), proof.B,
//            vk.alfa1, vk.beta2,
//            vk_x, vk.gamma2,
//            proof.C, vk.delta2
//        )) return 1;
//        return 0;
//    }
//    function fakeVerify(uint[] memory input, Proof memory proof) public view returns (uint) {
//        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
//        VerifyingKey memory vk = verifyingKey();
//        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
//        // Compute the linear combination vk_x
//        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
//        for (uint i = 0; i < input.length; i++) {
//            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
//            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
//        }
//        vk_x = Pairing.addition(vk_x, vk.IC[0]);
//        return 1;
//    }
//    function testAddition() public view returns (Pairing.G1Point memory) {
//        Pairing.G1Point memory a = Pairing.G1Point(10, 0);
//        Pairing.G1Point memory b = Pairing.G1Point(0, 10);
//        return Pairing.addition(a, b);
//    }
//    function testScalarMul() public view returns (Pairing.G1Point memory) {
//        Pairing.G1Point memory a = Pairing.G1Point(10, 10);
//        return Pairing.scalar_mul(a, 4);
//    }
//    /// @return r  bool true if proof is valid
//    function makeInputValues(
//        uint[2] memory a,
//        uint[2][2] memory b,
//        uint[2] memory c,
//        uint[5] memory input
//    ) public view returns (uint[] memory, Proof memory) {
//        Proof memory proof;
//        proof.A = Pairing.G1Point(a[0], a[1]);
//        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
//        proof.C = Pairing.G1Point(c[0], c[1]);
//        uint[] memory inputValues = new uint[](input.length);
//        for(uint i = 0; i < input.length; i++){
//            inputValues[i] = input[i];
//        }
//        return (inputValues, proof);
//    }
//    /// @return r  bool true if proof is valid
//    function verifyProof(
//        uint[2] memory a,
//        uint[2][2] memory b,
//        uint[2] memory c,
//        uint[5] memory input
//    ) public view returns (bool r) {
//        Proof memory proof;
//        proof.A = Pairing.G1Point(a[0], a[1]);
//        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
//        proof.C = Pairing.G1Point(c[0], c[1]);
//        uint[] memory inputValues = new uint[](input.length);
//        for(uint i = 0; i < input.length; i++){
//            inputValues[i] = input[i];
//        }
//        if (verify(inputValues, proof) == 0) {
//            return true;
//        } else {
//            return false;
//        }
//    }
//    /// @return r  bool true if proof is valid
//    function fakeVerifyProof(
//        uint[2] memory a,
//        uint[2][2] memory b,
//        uint[2] memory c,
//        uint[5] memory input
//    ) public view returns (bool r) {
//        Proof memory proof;
//        proof.A = Pairing.G1Point(a[0], a[1]);
//        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
//        proof.C = Pairing.G1Point(c[0], c[1]);
//        uint[] memory inputValues = new uint[](input.length);
//        for(uint i = 0; i < input.length; i++){
//            inputValues[i] = input[i];
//        }
//        if (fakeVerify(inputValues, proof) == 0) {
//            return true;
//        } else {
//            return false;
//        }
//    }
//}
