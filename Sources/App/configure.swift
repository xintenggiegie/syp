import Vapor
import APNS
import APNSwift
import Fluent
import FluentSQLiteDriver
import Foundation

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    app.databases.use(.sqlite(.memory), as: .sqlite)
//    if let databaseURL = Environment.get("DATABASE_URL") {
//        app.databases.use(try .postgres(
//            url: databaseURL
//        ), as: .psql)
//    } else {
//        // ...
//        
//    }

    app.migrations.add(AppMigration(), to: .sqlite)
    app.migrations.add(DeviceMigration(), to: .sqlite)
    
    try app.autoMigrate().wait()
    
    app.apns.configuration = try .init(
        authenticationMethod: .jwt(
            key: .private(pem: """
-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgsj/279tiMJPaZl71
/fyzH3yHZfYf2dBFII2fvrvQQe+gCgYIKoZIzj0DAQehRANCAAQIL+sEAC7I7s4+
6MLh/2GaIFwWKwkuo7cQ7ONTKgtF69VNPdECoI9Pzy7elUfDwSjh11+H+eiSBR1x
/sksLB0e
-----END PRIVATE KEY-----
"""),
            keyIdentifier: "G9KDXM9L7K",
            teamIdentifier: "ZEBW46K5SH"
        ),
        topic: "com.sooyie.tsmp",
        environment: .sandbox
    )

    Mqtt.shared.config(app)
    
    
    // register routes
    try routes(app)
    
}
