//
//  SourcesCommand.swift
//  SaberCLI
//
//  Created by andrey.pleshkov on 04/07/2018.
//

import Foundation
import Saber
import Commandant
import Result

struct SourcesCommand: CommandProtocol {

    let verb = "sources"
    let function = "Generate containers from sources"

    private let defaultConfig: SaberConfiguration

    init(config: SaberConfiguration) {
        self.defaultConfig = config
    }

    struct Options: OptionsProtocol {

        let inputDir: URL

        let outDir: URL

        let config: SaberConfiguration?
        
        let logLevel: String

        static func create(workDir: String)
            -> (_ inputPath: String)
            -> (_ outDir: String)
            -> (_ rawConfig: String)
            -> (_ logLevel: String)
            -> Options {
                let baseURL: URL? = workDir.count > 0
                    ? URL(fileURLWithPath: workDir, isDirectory: true)
                    : nil
                return { (inputPath) in
                    let inputDir = URL(fileURLWithPath: inputPath).saber_relative(to: baseURL)
                    return { (outPath) in
                        let outDir = URL(fileURLWithPath: outPath).saber_relative(to: baseURL)
                        return { (rawConfig) in
                            let config: SaberConfiguration? = try? ConfigDecoder(raw: rawConfig).decode(baseURL: baseURL)
                            return { (logLevel) in
                                self.init(
                                    inputDir: inputDir,
                                    outDir: outDir,
                                    config: config,
                                    logLevel: logLevel
                                )
                            }
                        }
                    }
                }
        }

        static func evaluate(_ m: CommandMode) -> Result<Options, CommandantError<Throwable>> {
            return create
                <*> m <| Option(key: "workDir", defaultValue: "", usage: "Working directory (optional)")
                <*> m <| Option(key: "from", defaultValue: "", usage: "Directory with sources (is relative to --workDir if any)")
                <*> m <| Option(key: "out", defaultValue: "", usage: "Output directory (is relative to --workDir if any)")
                <*> m <| Option(key: "config", defaultValue: "", usage: "Path to *.yml or YAML text (optional)")
                <*> m <| Option(key: "log", defaultValue: "info", usage: "Could be 'info' (by default) or 'debug' (optional)")
        }
    }

    func run(_ options: Options) -> Result<(), Throwable> {
        do {
            Logger = ConsoleLogger(level: try LogLevel.make(from: options.logLevel))
            let config = options.config ?? defaultConfig
            let factory = ParsedDataFactory()
            try DirectoryTraverser.traverse(options.inputDir.path) { (path) in
                if path.hasSuffix(FileRenderer.fileSuffix) {
                    Logger?.info("Ignoring '\(path)': generated by Saber")
                    return
                }
                guard path.hasSuffix(".swift") else {
                    Logger?.info("Ignoring '\(path)': not a swift file")
                    return
                }
                let parser = try FileParser(path: path, config: config)
                try parser.parse(to: factory)
            }
            try FileRenderer.render(
                params: FileRenderer.Params(
                    version: saberVersion,
                    parsedDataFactory: factory,
                    outDir: options.outDir,
                    config: config
                )
            )
            return .success(())
        } catch {
            return .failure(.wrapped(error))
        }
    }
}
