//
//  CompilationEngine.swift
//  JackAnalyzer
//
//  Created by Алексей Якименко on 14.04.2021.
//

import Foundation

enum CompilationEngineError: Error {
    case noMoreTokens
    case wrongKeyword
    case keywordNotFound
    case wrongSymbol
    case symbolNotFound
    case identifierNotFound
}

final class CompilationEngine {
    
    private let _keywords: [Keyword: String] = [
        .class: "class",
        .constructor: "constructor",
        .function: "function",
        .method: "method",
        .field: "field",
        .static: "static",
        .var: "var",
        .int: "int",
        .char: "char",
        .boolean: "boolean",
        .void: "void",
        .true: "true",
        .false: "false",
        .null: "null",
        .this: "this",
        .let: "let",
        .do: "do",
        .if: "if",
        .else: "else",
        .while: "while",
        .return: "return"
    ]
    
    private let _symbols: [Symbol: String] = [
        .openingCurlyBracket: "{",
        .closingCurlyBracket: "}",
        .openingRoundBracket: "(",
        .closingRoundBracket: ")",
        .openingSquareBracket: "]",
        .closingSquareBracket: "[",
        .dot: ".",
        .comma: ",",
        .simecolons: ";",
        .plusSign: "+",
        .minusSign: "-",
        .multiplicationSign: "*",
        .divisionSign: "/",
        .ampersand: "&",
        .verticalBar: "|",
        .less: "<",
        .more: ">",
        .equal: "=",
        .tilde: "~"
    ]
    
    private let tokenizer: Tokenizer
    private var ast: String = ""
    private var unprocessedToken: Bool = false
    
    init(_ tokenizer: Tokenizer) {
        self.tokenizer = tokenizer
    }
    
    func compileClass() throws {
        ast.append("<class>")
        try takeNextToken(eatKeyword(.class))
        try takeNextToken(eatIdentifier())
        try takeNextToken(eatSymbol(.openingCurlyBracket))
        try zeroOrMore(compileVarDec())
        try zeroOrMore(compileSubroutineDec())
        try takeNextToken(eatSymbol(.closingCurlyBracket))
        ast.append("</class>")
    }
    
    func compileClassVarDec() throws {
        ast.append("<classVarDec>")
        try takeNextToken(or(self.eatKeyword(.static),
                             self.eatKeyword(.field)))
        try takeNextToken(eatType())
        try takeNextToken(eatIdentifier())
        try zeroOrMore(takeNextToken(eatIdentifier()))
        try takeNextToken(eatSymbol(.simecolons))
        ast.append("</classVarDec>")
    }
    
    func compileSubroutineDec() throws {
        ast.append("<subroutineDec>")
        try takeNextToken(or(self.eatKeyword(.constructor),
                             self.eatKeyword(.function),
                             self.eatKeyword(.method)))
        try takeNextToken(or(self.eatKeyword(.void),
                             self.eatType()))
        try takeNextToken(eatIdentifier())
        try takeNextToken(eatSymbol(.openingRoundBracket))
        try compileParameterList()
        try takeNextToken(eatSymbol(.closingRoundBracket))
        try compileSubroutineBody()
        ast.append("</subroutineDec>")
    }
    
    func compileParameterList() throws {
        ast.append("<parameterList>")
        try takeNextToken(eatType())
        try takeNextToken(eatIdentifier())
        ast.append("</parameterList>")
    }
    
    func compileSubroutineBody() throws {
        ast.append("<subroutineBody>")
        try takeNextToken(eatSymbol(.openingCurlyBracket))
        try compileVarDec()
        try compileStatements()
        try takeNextToken(eatSymbol(.closingCurlyBracket))
        ast.append("</subroutineBody>")
    }
    
    func compileVarDec() throws {
        ast.append("<varDec>")
        try takeNextToken(eatKeyword(.var))
        try takeNextToken(eatType())
        try takeNextToken(eatIdentifier())
        ast.append("</varDec>")
    }
    
    func compileStatements() throws {
        ast.append("<statements>")
        ast.append("</statements>")
    }
    
    func compileLet() throws {
        ast.append("<LetStatement>")
        ast.append("</LetStatement>")
    }
    
    func compileIf() throws {
        ast.append("<ifStatement>")
        ast.append("</ifStatement>")
    }
    
    func compileWhile() throws {
        ast.append("<whileStatement>")
        try eatKeyword(.while)
        try eatSymbol(.openingRoundBracket)
        try compileExpression()
        try eatSymbol(.closingRoundBracket)
        try eatSymbol(.openingCurlyBracket)
        try compileStatements()
        try eatSymbol(.closingCurlyBracket)
        ast.append("</whileStatement>")
    }
    
    func compileDo() throws {
        ast.append("<doStatement>")
        try eatKeyword(.do)
        ast.append("</doStatement>")
    }
    
    func compileReturn() throws {
        ast.append("<returnStatement>")
        ast.append("</returnStatement>")
    }
    
    func compileExpression() throws {
        ast.append("<expressionStatement>")
        ast.append("</expressionStatement>")
    }
    
    func compileTerm() throws {
        ast.append("<term>")
        ast.append("</term>")
    }
    
    func compileExpressionList() throws {
        ast.append("<expressionList>")
        ast.append("</expressionList>")
    }
    
    func xml() -> String {
        ast
    }
}

private extension CompilationEngine {
    
    func takeNextToken(_ f: @autoclosure () throws -> Void) throws {
        guard !unprocessedToken else { return }
        if tokenizer.hasMoreTokens() {
            tokenizer.advance()
            do {
                try f()
            } catch {
                unprocessedToken = true
                throw error
            }
        } else {
            throw CompilationEngineError.noMoreTokens
        }
    }
    
    func zeroOrOne(_ f: @autoclosure () throws -> Void) throws {
        var stop: Bool = false
        var count: Int = 0
        while (!stop || count == 1) {
            do {
                try f()
                count += 1
            } catch CompilationEngineError.keywordNotFound {
                stop = true
            } catch CompilationEngineError.symbolNotFound {
                stop = true
            } catch CompilationEngineError.identifierNotFound {
                stop = true
            }
        }
    }
    
    func zeroOrMore(_ f: @autoclosure () throws -> Void) throws {
        var stop: Bool = false
        while (!stop) {
            do {
                try f()
            } catch CompilationEngineError.keywordNotFound {
                stop = true
            } catch CompilationEngineError.symbolNotFound {
                stop = true
            } catch CompilationEngineError.identifierNotFound {
                stop = true
            }
        }
    }

    func eatType() throws {
        try or(self.eatKeyword(.int),
               self.eatKeyword(.char),
               self.eatKeyword(.boolean),
               self.eatIdentifier())
    }
    
    func eatKeyword(_ keyword: Keyword) throws {
        if tokenizer.tokenType() == .keyword {
            if try tokenizer.keyword() == keyword {
                ast.append("<keyword>")
                ast.append(_keywords[keyword]!)
                ast.append("</keyword>")
            } else {
                throw CompilationEngineError.wrongKeyword
            }
        } else {
            throw CompilationEngineError.keywordNotFound
        }
    }
    
    func eatSymbol(_ symbol: Symbol) throws {
        if tokenizer.tokenType() == .symbol {
            if try tokenizer.symbol() == symbol {
                ast.append("<symbol>")
                ast.append(_symbols[symbol]!)
                ast.append("</symbol>")
            } else {
                throw CompilationEngineError.wrongSymbol
            }
        } else {
            throw CompilationEngineError.symbolNotFound
        }
    }
    
    func eatIdentifier() throws {
        if tokenizer.tokenType() == .identifier {
            ast.append("<identifier>")
            ast.append(try tokenizer.identifier())
            ast.append("</identifier>")
        } else {
            throw CompilationEngineError.identifierNotFound
        }
    }
}
