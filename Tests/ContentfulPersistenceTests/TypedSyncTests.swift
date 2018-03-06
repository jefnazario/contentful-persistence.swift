//
//  TypedSyncTests.swift
//  ContentfulPersistence
//
//  Created by JP Wright on 06.03.18.
//  Copyright © 2018 Contentful GmbH. All rights reserved.
//

import Foundation
@testable import ContentfulPersistence
import Contentful
import Interstellar
import XCTest
import CoreData
import Nimble

@objc(Cat)
final class Cat: NSManagedObject, EntryDecodable, EntryQueryable {

    static let contentTypeId: String = "cat"

    var sys: Sys = Sys(id: "", type: "")
    @NSManaged var color: String?
    @NSManaged var name: String?
//    @NSManaged var lives: Int?
//    @NSManaged var likes: [String]?

    // Relationship fields.
    var bestFriend: Cat?
    var image: Asset?

    public convenience init(from decoder: Decoder) throws {
        // Create NSEntityDescription with NSManagedObjectContext
        guard let managedObjectContext = decoder.userInfo[.managedObjectContextKey] as? NSManagedObjectContext,
            let entity = NSEntityDescription.entity(forEntityName: String(describing: Cat.self), in: managedObjectContext) else {
                fatalError("Failed to decode Person!")
        }
        self.init(entity: entity, insertInto: managedObjectContext)

//        sys             = try decoder.sys()
        let fields      = try decoder.contentfulFieldsContainer(keyedBy: Cat.Fields.self)

        self.name       = try fields.decodeIfPresent(String.self, forKey: .name)
        self.color      = try fields.decodeIfPresent(String.self, forKey: .color)
//        self.likes      = try fields.decodeIfPresent(Array<String>.self, forKey: .likes)
//        self.lives      = try fields.decodeIfPresent(Int.self, forKey: .lives)

        try fields.resolveLink(forKey: .bestFriend, decoder: decoder) { [weak self] linkedCat in
            self?.bestFriend = linkedCat as? Cat
        }
        try fields.resolveLink(forKey: .image, decoder: decoder) { [weak self ] image in
            self?.image = image as? Asset
        }
    }

    enum Fields: String, CodingKey {
        case bestFriend, image
        case name, color, likes, lives
    }
}
@objc(City)
final class City: NSManagedObject, EntryDecodable, EntryQueryable {

    static let contentTypeId: String = "1t9IbcfdCk6m04uISSsaIK"

    var sys: Sys = Sys(id: "", type: "")
    @NSManaged var location: Location?

    public convenience init(from decoder: Decoder) throws {
        // Create NSEntityDescription with NSManagedObjectContext
        guard let managedObjectContext = decoder.userInfo[.managedObjectContextKey] as? NSManagedObjectContext,
            let entity = NSEntityDescription.entity(forEntityName: String(describing: City.self), in: managedObjectContext) else {
                fatalError("Failed to decode Person!")
        }
        self.init(entity: entity, insertInto: managedObjectContext)


//        sys             = try decoder.sys()
        let fields      = try decoder.contentfulFieldsContainer(keyedBy: City.Fields.self)

        self.location   = try fields.decode(Location.self, forKey: .location)
    }

    enum Fields: String, CodingKey {
        case location = "center"
    }
}

extension Sys {
    public init(id: String, type: String) {
        self.id = id
        self.type = type
        self.createdAt = nil
        self.updatedAt = nil
        self.locale = nil

        self.contentTypeInfo = nil
        self.revision = nil
    }
}

@objc(Dog)
final class Dog: NSManagedObject, EntryDecodable, EntryQueryable {

    static let contentTypeId: String = "dog"

    var sys: Sys = Sys(id: "", type: "")

    @NSManaged var name: String!
    @NSManaged var dogDescription: String?

    @NSManaged var image: Asset?

    public convenience init(from decoder: Decoder) throws {
        // Create NSEntityDescription with NSManagedObjectContext
        guard let managedObjectContext = decoder.userInfo[.managedObjectContextKey] as? NSManagedObjectContext,
            let entity = NSEntityDescription.entity(forEntityName: String(describing: Dog.self), in: managedObjectContext) else {
                fatalError("Failed to decode Person!")
        }
        self.init(entity: entity, insertInto: managedObjectContext)

//        sys             = try decoder.sys()
        let fields      = try decoder.contentfulFieldsContainer(keyedBy: Dog.Fields.self)
        name            = try fields.decode(String.self, forKey: .name)
        dogDescription     = try fields.decodeIfPresent(String.self, forKey: .dogDescription)

//        try fields.resolveLink(forKey: .image, decoder: decoder) { [weak self] linkedImage in
//            self?.image = linkedImage as? Asset
//        }
    }

    enum Fields: String, CodingKey {
        case image, name
        case dogDescription = "description"
    }
}



class TypedSyncTests: XCTestCase {

    static let client: Client = {
        let contentTypeClasses: [EntryDecodable.Type] = [
            Cat.self,
            Dog.self,
            City.self
        ]
        return Client(spaceId: "dumri3ebknon",
                      accessToken: "e566e6f1d0545862159b6c63fddd25bebe0aa5c1bb8cbf9418c8531feff0d564",
                      contentTypeClasses: contentTypeClasses)
    }()

    func testSync() {
        let expectation = self.expectation(description: "Sync test expecation")
        TypedSyncTests.client.jsonDecoder.managedObjectContext = TestHelpers.managedObjectContext(forMOMInTestBundleNamed: "CFExampleAPIModel")

        TypedSyncTests.client.shallowSync(syncableTypes: .entries) { result in
            switch result {
            case .success(let shallowSyncSpace):

                expect(shallowSyncSpace.items.count).to(equal(18)) // 9*2
            case .error(let error):
                print(error)
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }
}

