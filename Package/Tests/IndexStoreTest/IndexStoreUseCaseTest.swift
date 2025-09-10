//
//  IndexStoreUseCaseTest.swift
//  Package
//
//  Created by Ockey on 2025/09/09.
//

import CustomDump
import Foundation
import Location
import TestData
import Testing

@testable import IndexStore

@Test
func extractUSRsFromTestData() async throws {
    // test data file: /swift-kraken/Package/Sources/TestData/Method.swift
    let indexStoreURL = try #require(TestHelper.findIndexStorePath())
    let testFileURL = TestHelper.getTestDataFileURL(fileNameWithExtension: "Method.swift")
    let fullPath = testFileURL.path()
    let useCase = IndexStoreUseCase(repository: LiveIndexStoreRepository())
    let response = try await useCase.extractUSR(indexStoreURL: indexStoreURL, projectRootURL: testFileURL)
    let expectedResult = IndexStoreUseCase.Response(
        definitionUSRs: [
            // ParameterType
            Location(fullPath: fullPath, line: 8, column: 8): [
                USR("s:8TestData13ParameterTypeV"),
                USR("s:8TestData13ParameterTypeVACycfc"),
            ],
            // ReturnValueType
            Location(fullPath: fullPath, line: 10, column: 8): [
                USR("s:8TestData15ReturnValueTypeV"),
                USR("s:8TestData15ReturnValueTypeVACycfc"),
            ],
            // OutOfSignatureType
            Location(fullPath: fullPath, line: 12, column: 8): [
                USR("s:8TestData18OutOfSignatureTypeV"),
                USR("s:8TestData18OutOfSignatureTypeVACycfc"),
            ],
            // TypeWithMethod
            Location(fullPath: fullPath, line: 14, column: 8): [
                USR("s:8TestData14TypeWithMethodV"),
                USR("s:8TestData14TypeWithMethodVACycfc"),
            ],
            // TypeWithMethod.method
            Location(fullPath: fullPath, line: 15, column: 10): [
                USR("s:8TestData14TypeWithMethodV6method5paramAA011ReturnValueC0VAA09ParameterC0V_tF"),
            ],
            // TypeWithMethod.method.param
            Location(fullPath: fullPath, line: 15, column: 23): [
                USR("s:8TestData14TypeWithMethodV6method5paramAA011ReturnValueC0VAA09ParameterC0V_tF1_L_AIvp"),
            ],
        ],
        referrerUSRs: [
            // TypeWithMethod.method -> ParameterType
            USR("s:8TestData13ParameterTypeV"): [
                Occurrence(
                    usr: USR("s:8TestData14TypeWithMethodV6method5paramAA011ReturnValueC0VAA09ParameterC0V_tF"),
                    location: Location(fullPath: fullPath, line: 15, column: 26),
                ),
            ],
            // TypeWithMethod.method -> ReturnValueType
            USR("s:8TestData15ReturnValueTypeV"): [
                Occurrence(
                    usr: USR("s:8TestData14TypeWithMethodV6method5paramAA011ReturnValueC0VAA09ParameterC0V_tF"),
                    location: Location(fullPath: fullPath, line: 15, column: 44),
                ),
                Occurrence(
                    usr: USR("s:8TestData14TypeWithMethodV6method5paramAA011ReturnValueC0VAA09ParameterC0V_tF"),
                    location: Location(fullPath: fullPath, line: 17, column: 16),
                ),
            ],
            // TypeWithMethod.method -> ReturnValueType.init
            USR("s:8TestData15ReturnValueTypeVACycfc"): [
                Occurrence(
                    usr: USR("s:8TestData14TypeWithMethodV6method5paramAA011ReturnValueC0VAA09ParameterC0V_tF"),
                    location: Location(fullPath: fullPath, line: 17, column: 16),
                ),
            ],
            // TypeWithMethod.method -> OutOfSignatureType
            USR("s:8TestData18OutOfSignatureTypeV"): [
                Occurrence(
                    usr: USR("s:8TestData14TypeWithMethodV6method5paramAA011ReturnValueC0VAA09ParameterC0V_tF"),
                    location: Location(fullPath: fullPath, line: 16, column: 15),
                ),
            ],
            // TypeWithMethod.method -> OutOfSignatureType.init
            USR("s:8TestData18OutOfSignatureTypeVACycfc"): [
                Occurrence(
                    usr: USR("s:8TestData14TypeWithMethodV6method5paramAA011ReturnValueC0VAA09ParameterC0V_tF"),
                    location: Location(fullPath: fullPath, line: 16, column: 15),
                ),
            ],
            // TypeWithMethod.method -> print
            USR("s:s5print_9separator10terminatoryypd_S2StF"): [
                Occurrence(
                    usr: USR("s:8TestData14TypeWithMethodV6method5paramAA011ReturnValueC0VAA09ParameterC0V_tF"),
                    location: Location(fullPath: fullPath, line: 16, column: 9),
                ),
            ],
        ],
        referencedUSRs: [
            USR("s:8TestData14TypeWithMethodV6method5paramAA011ReturnValueC0VAA09ParameterC0V_tF"): [
                // TypeWithMethod.method -> ParameterType
                Occurrence(
                    usr: USR("s:8TestData13ParameterTypeV"),
                    location: Location(fullPath: fullPath, line: 15, column: 26),
                ),
                // TypeWithMethod.method -> ReturnValueType
                Occurrence(
                    usr: USR("s:8TestData15ReturnValueTypeV"),
                    location: Location(fullPath: fullPath, line: 15, column: 44),
                ),
                Occurrence(
                    usr: USR("s:8TestData15ReturnValueTypeV"),
                    location: Location(fullPath: fullPath, line: 17, column: 16),
                ),
                // TypeWithMethod.method -> ReturnValueType.init
                Occurrence(
                    usr: USR("s:8TestData15ReturnValueTypeVACycfc"),
                    location: Location(fullPath: fullPath, line: 17, column: 16),
                ),
                // TypeWithMethod.method -> OutOfSignatureType
                Occurrence(
                    usr: USR("s:8TestData18OutOfSignatureTypeV"),
                    location: Location(fullPath: fullPath, line: 16, column: 15),
                ),
                // TypeWithMethod.method -> OutOfSignatureType.init
                Occurrence(
                    usr: USR("s:8TestData18OutOfSignatureTypeVACycfc"),
                    location: Location(fullPath: fullPath, line: 16, column: 15),
                ),
                // TypeWithMethod.method -> print
                Occurrence(
                    usr: USR("s:s5print_9separator10terminatoryypd_S2StF"),
                    location: Location(fullPath: fullPath, line: 16, column: 9),
                ),
            ],
        ],
    )

    expectNoDifference(expectedResult, response)
}
