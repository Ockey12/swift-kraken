//
//  Method.swift
//  Package
//
//  Created by Ockey on 2025/09/09.
//

struct ParameterType {}

struct ReturnValueType {}

struct OutOfSignatureType {}

struct TypeWithMethod {
    func method(param _: ParameterType) -> ReturnValueType {
        print(OutOfSignatureType())
        return ReturnValueType()
    }
}
