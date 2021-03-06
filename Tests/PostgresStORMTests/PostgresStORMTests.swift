import XCTest
import PerfectLib
//import Foundation
import StORM
@testable import PostgresStORM

enum Gender : String, CustomStringConvertible, CustomDatabaseTypeConvertible {
    var type: String { return "text" }
    var description: String { return self.rawValue }
    case male = "Male", female = "Female", unknown
}

class AuditFields: PostgresStORM {
    
    /// This is when the table row has been created.
    var created : Int?           = nil
    /// This is the id of the user that has created the row.
    var createdby : String?  = nil
    /// This is when the table row has been modified.
    var modified : Int?          = nil
    /// This is the id of the user that has modified the row.
    var modifiedby : String? = nil
    
    // This is needed when created a subclass containing other fields to re-use for other models.
    required init() {
        super.init()
        self.didInitializeSuperclass()
    }
}

// The outer most class does not need to override init & call didInitializeSuperclass.  This helps with identifying the id in the model.
class TestUser2: AuditFields, Equatable {
    static func == (lhs: TestUser2, rhs: TestUser2) -> Bool {
        if lhs.id == nil, lhs.id == rhs.id {
            return lhs.firstname == rhs.firstname && lhs.lastname == rhs.lastname && lhs.phonenumber == rhs.phonenumber && lhs.geopoint == rhs.geopoint
        }
        return lhs.id == rhs.id
    }
    
    // Notice we now do not need to put id at the top.  However, this is backwards compatable, meaning if you do not want to subclass, or if someone updates & has the same models as configured before, they do not need to add any extra code to set the primaryKeyLabel.
    var firstname : String?          = nil {
        didSet {
            if oldValue != nil && firstname == nil {
                self.nullColumns.insert("firstname")
            } else if firstname != nil {
                self.nullColumns.remove("firstname")
            }
        }
    }
    var lastname : String?          = nil {
        didSet {
            if oldValue != nil && lastname == nil {
                self.nullColumns.insert("lastname")
            } else if lastname != nil {
                self.nullColumns.remove("lastname")
            }
        }
    }
    var phonenumber : String? = nil {
        didSet {
            if oldValue != nil && phonenumber == nil {
                self.nullColumns.insert("phonenumber")
            } else if phonenumber != nil {
                self.nullColumns.remove("phonenumber")
            }
        }
    }
    
    var gender : Gender = .unknown
    
    var id : Int?                             = nil
    
    var money = PostgresNumeric(14, 3) {
        didSet {
            if oldValue.value != nil && money.value == nil {
                self.nullColumns.insert("money")
            } else if money.value != nil {
                self.nullColumns.remove("money")
            }
        }
    }
    
    var geopoint = GeographyPoint() {
        didSet {
            if geopoint.longitude == nil, geopoint.latitude == nil, (oldValue.latitude != nil || oldValue.longitude != nil) {
                self.nullColumns.insert("geopoint")
            } else if geopoint.longitude != nil, geopoint.latitude != nil, (oldValue.latitude == nil || oldValue.longitude == nil) {
                self.nullColumns.remove("geopoint")
            }
        }
    }
    
    override open func table() -> String {
        return "testuser2"
    }
    
    // This is only needed if the id for the table is outside the scope of this class.  This also gives us the flexibilty of having the primary key placed anywhere in the model.
    override open func primaryKeyLabel() -> String? {
        return "id"
    }
    
    override func to(_ this: StORMRow) {
        
        // Audit fields:
        id                = this.data["id"] as? Int
        created     = this.data["created"] as? Int
        createdby     = this.data["createdby"] as? String
        modified     = this.data["modified"] as? Int
        modifiedby     = this.data["modifiedby"] as? String
        
        firstname        = this.data["firstname"] as? String
        lastname        = this.data["lastname"] as? String
        phonenumber            = this.data["phonenumber"] as? String
        geopoint.from(this.data["geopoint"])
        
    }
    
    func rows() -> [TestUser2] {
        var rows = [TestUser2]()
        for i in 0..<self.results.rows.count {
            let row = TestUser2()
            row.to(self.results.rows[i])
            rows.append(row)
        }
        return rows
    }
    
}

class TestUser: AuditFields {
    
    // The id still needs to be first if the primaryKeyLabel for StORM is not set to anything.
    // If the id needs to be in another superclass, set the primaryKeyLabel for StORM.
    var id : String? = nil
    var firstName : String? = nil
    var lastName : String? = nil
    var phoneNumber : String? = nil
    
    var currentAmount = PostgresNumeric(12, 4)
    // OR
    var anotherAmount = PostgresNumeric(10,4, default: 5.0)
    
    override open func table() -> String {
        return "testuser"
    }

    override func to(_ this: StORMRow) {
        
        // Audit fields:
        id                = this.data["id"] as? String
        created     = this.data["created"] as? Int
        createdby     = this.data["createdby"] as? String
        modified     = this.data["modified"] as? Int
        modifiedby     = this.data["modifiedby"] as? String
        
        firstName        = this.data["firstname"] as? String
        lastName        = this.data["lastname"] as? String
        phoneNumber            = this.data["phonenumber"] as? String
        currentAmount.from(this.data["currentamount"])
        anotherAmount.from(this.data["anotheramount"])
        
    }
    
    func rows() -> [TestUser] {
        var rows = [TestUser]()
        for i in 0..<self.results.rows.count {
            let row = TestUser()
            row.to(self.results.rows[i])
            rows.append(row)
        }
        return rows
    }
    
}

class User: PostgresStORM {
	// NOTE: First param in class should be the ID.
	var id				: Int = 0
	var firstname		: String = ""
	var lastname		: String = ""
	var email			: String = ""
	var stringarray		= [String]()


	override open func table() -> String {
		return "users_test1"
	}

	override func to(_ this: StORMRow) {
		id				= this.data["id"] as? Int ?? 0
		firstname		= this.data["firstname"] as? String ?? ""
		lastname		= this.data["lastname"] as? String ?? ""
		email			= this.data["email"] as? String ?? ""
		stringarray		= toArrayString(this.data["stringarray"] as? String ?? "")
	}

	func rows() -> [User] {
		var rows = [User]()
		for i in 0..<self.results.rows.count {
			let row = User()
			row.to(self.results.rows[i])
			rows.append(row)
		}
		return rows
	}
}


class PostgresStORMTests: XCTestCase {

	override func setUp() {
		super.setUp()
        #if os(Linux)

            PostgresConnector.host        = ProcessInfo.processInfo.environment["HOST"]!
            PostgresConnector.username    = ProcessInfo.processInfo.environment["USER"]!
            PostgresConnector.password    = ProcessInfo.processInfo.environment["PASS"]!
            PostgresConnector.database    = ProcessInfo.processInfo.environment["DB"]!
            PostgresConnector.port        = Int(ProcessInfo.processInfo.environment["PORT"]!)!

        #else
            PostgresConnector.host        = "localhost"
            PostgresConnector.username    = "perfect"
            PostgresConnector.password    = "perfect"
            PostgresConnector.database    = "perfect_testing"
            PostgresConnector.port        = 5432
        #endif
        
//        let user = TestUser()
//        try? user.setup()
        
        let user2 = TestUser2()
        try? user2.setup(autoIncrementPK: true)
        
        StORMdebug = true
        
	}
    
    // New test cases:
    func testNewModelStructureWithAuditUserId() {
        
        let user = TestUser2()
        
        user.firstname = "Test"
        user.lastname = "Test"
        user.phonenumber = "15555555555"
        user.geopoint.longitude = -77
        user.geopoint.latitude = 38
        user.money.value = 24.45
        
        do {
        
            try user.save(auditUserId: "MyUserIdTest", didSet: { id in let id = id as? Int
                user.id = id
            })
            
        } catch {
            XCTFail(String(describing: error))
        }
        XCTAssert(user.id != nil, "Object not saved (new)")
        
    }
    
    func testUpdateModel() {
        
        let user = TestUser2()
        
        try? user.get(6)
        
        user.lastname = nil
        user.geopoint.longitude = nil
        user.geopoint.latitude = nil
//        user.money.value = 22.54
        
        do {
            
            try user.save(auditUserId: "MyUserIdTest")
            
        } catch {
            XCTFail(String(describing: error))
        }
        XCTAssert(user.id != nil, "Object not saved (new)")
        
    }
    
    func testAutomaticModified() {
        
        let user = TestUser2()
        
        user.id = 3
        user.firstname = "Ryan3"
        
        try? user.save()
        
    }
    
    func testGetAndSetNull() {
        
        let user = TestUser2()
        try? user.get(1)
        
        if user.id != nil {
            
            user.lastname = nil
            try? user.save(auditUserId: "TestUserBit")
            
        } else {
            
        }
        
    }
    
    func testCreateAndSave() {
        
        let user = TestUser()

        user.id = UUID().uuidString
        user.firstName = "Test"
        user.lastName = "Test"
        user.phoneNumber = "15555555555"
        user.currentAmount.value = 0.02
        
        do {
            try user.create()
            
            user.firstName = "Test 2"
            
            try user.save()
            
        } catch {
            XCTFail(String(describing: error))
        }
        XCTAssert(user.id != nil, "Object not saved (new)")
    }
    
	/* =============================================================================================
	Save - New
	============================================================================================= */
	func testSaveNew() {

		let obj = User()
		obj.firstname = "X"
		obj.lastname = "Y"

		do {
			try obj.save {id in obj.id = id as! Int }
		} catch {
			XCTFail(String(describing: error))
		}
		XCTAssert(obj.id > 0, "Object not saved (new)")
	}
    
	/* =============================================================================================
	Save - Update
	============================================================================================= */
	func testSaveUpdate() {
		let obj = User()
		obj.firstname = "X"
		obj.lastname = "Y"

		do {
			try obj.save {id in obj.id = id as! Int }
		} catch {
			XCTFail(String(describing: error))
		}

		obj.firstname = "A"
		obj.lastname = "B"
		do {
			try obj.save()
		} catch {
			XCTFail(String(describing: error))
		}
		print(obj.errorMsg)
		XCTAssert(obj.id > 0, "Object not saved (update)")
	}

	/* =============================================================================================
	Save - Create
	============================================================================================= */
	func testSaveCreate() {
		// first clean up!
		let deleting = User()
		do {
			deleting.id			= 10001
			try deleting.delete()
		} catch {
			XCTFail(String(describing: error))
		}

		let obj = User()

		do {
			obj.id			= 10001
			obj.firstname	= "Mister"
			obj.lastname	= "PotatoHead"
			obj.email		= "potato@example.com"
			try obj.create()
		} catch {
			XCTFail(String(describing: error))
		}
		XCTAssert(obj.id == 10001, "Object not saved (create)")
	}

	/* =============================================================================================
	Get (with id)
	============================================================================================= */
	func testGetByPassingID() {
		let obj = User()
		obj.firstname = "X"
		obj.lastname = "Y"

		do {
			try obj.save {id in obj.id = id as! Int }
		} catch {
			XCTFail(String(describing: error))
		}

		let obj2 = User()

		do {
			try obj2.get(obj.id)
		} catch {
			XCTFail(String(describing: error))
		}
		XCTAssert(obj.id == obj2.id, "Object not the same (id)")
		XCTAssert(obj.firstname == obj2.firstname, "Object not the same (firstname)")
		XCTAssert(obj.lastname == obj2.lastname, "Object not the same (lastname)")
	}


	/* =============================================================================================
	Get (by id set)
	============================================================================================= */
	func testGetByID() {
		let obj = User()
		obj.firstname = "X"
		obj.lastname = "Y"

		do {
			try obj.save {id in obj.id = id as! Int }
		} catch {
			XCTFail(String(describing: error))
		}

		let obj2 = User()
		obj2.id = obj.id
		
		do {
			try obj2.get()
		} catch {
			XCTFail(String(describing: error))
		}
		XCTAssert(obj.id == obj2.id, "Object not the same (id)")
		XCTAssert(obj.firstname == obj2.firstname, "Object not the same (firstname)")
		XCTAssert(obj.lastname == obj2.lastname, "Object not the same (lastname)")
	}

	/* =============================================================================================
	Get (with id) - integer too large
	============================================================================================= */
	func testGetByPassingIDtooLarge() {
		let obj = User()

		do {
			try obj.get(874682634789)
			XCTFail("Should have failed (integer too large)")
		} catch {
			print("^ Ignore this error, that is expected and should show 'ERROR:  value \"874682634789\" is out of range for type integer'")
			// test passes - should have a failure!
		}
	}
	
	/* =============================================================================================
	Get (with id) - no record
	// test get where id does not exist (id)
	============================================================================================= */
	func testGetByPassingIDnoRecord() {
		let obj = User()

		do {
			try obj.get(1111111)
			XCTAssert(obj.results.cursorData.totalRecords == 0, "Object should have found no rows")
		} catch {
			XCTFail(error as! String)
		}
	}




	// test get where id does not exist ()
	/* =============================================================================================
	Get (preset id) - no record
	// test get where id does not exist (id)
	============================================================================================= */
	func testGetBySettingIDnoRecord() {
		let obj = User()
		obj.id = 1111111
		do {
			try obj.get()
			XCTAssert(obj.results.cursorData.totalRecords == 0, "Object should have found no rows")
		} catch {
			XCTFail(error as! String)
		}
	}


	/* =============================================================================================
	Returning DELETE statement to verify correct form
	// deleteSQL
	============================================================================================= */
	func testCheckDeleteSQL() {
		let obj = User()
		XCTAssert(obj.deleteSQL("test", idName: "testid") == "DELETE FROM test WHERE \"testid\" = $1", "DeleteSQL statement is not correct")

	}



	/* =============================================================================================
	Find
	============================================================================================= */
	func testFind() {
		// Ensure table is empty
		do {
			let obj = User()
			let tableName = obj.table()
			_ = try? obj.sql("DELETE FROM \(tableName)", params: [])
		}

		// Doing a `find` with an empty table should yield zero results
		do {
			let obj = User()
			do {
				try obj.find([("lastname", "Ashpool")])
				XCTAssertEqual(obj.results.rows.count, 0)
				XCTAssertEqual(obj.results.cursorData.totalRecords, 0)
			} catch {
				XCTFail("Find error: \(obj.error.string())")
			}
		}

		// Insert more rows than the StORMCursor().limit
		for i in 0..<200 {
			let obj = User()
			obj.firstname = "Tessier\(i)"
			obj.lastname = "Ashpool"
			do {
				try obj.save { id in obj.id = id as! Int }
			} catch {
				XCTFail(String(describing: error))
			}
		}
		for i in 0..<10 {
			let obj = User()
			obj.firstname = "Molly\(i)"
			do {
				try obj.save { id in obj.id = id as! Int }
			} catch {
				XCTFail(String(describing: error))
			}
		}

		// Doing the same `find` should now return rows
		do {
			let obj = User()
			do {
				try obj.find([("lastname", "Ashpool")])
				let cursorLimit: Int = StORMCursor().limit
				XCTAssertEqual(obj.results.rows.count, cursorLimit, "Object should have found the all the rows just inserted. Limited by the default cursor limit.")
				XCTAssertEqual(obj.results.cursorData.totalRecords, 200, "Object should have found the all the rows just inserted")
			} catch {
				XCTFail("Find error: \(obj.error.string())")
			}
		}

		// Doing the same `find` should now return rows limited by the provided cursor limit
		do {
			let obj = User()
			do {
				let cursor = StORMCursor(limit: 150, offset: 0)
				try obj.find(["lastname": "Ashpool"], cursor: cursor)
				XCTAssertEqual(obj.results.rows.count, cursor.limit, "Object should have found the all the rows just inserted. Limited by the provided cursor limit.")
				XCTAssertEqual(obj.results.cursorData.totalRecords, 200, "Object should have found the all the rows just inserted")
			} catch {
				XCTFail("Find error: \(obj.error.string())")
			}
		}
	}
	
	/* =============================================================================================
	FindAll
	============================================================================================= */
	func testFindAll() {
		// Ensure table is empty
		do {
			let obj = User()
			let tableName = obj.table()
			_ = try? obj.sql("DELETE FROM \(tableName)", params: [])
		}

		// Insert more rows than the StORMCursor().limit
		for i in 0..<200 {
			let obj = User()
			obj.firstname = "Wintermute\(i)"
			do {
				try obj.save { id in obj.id = id as! Int }
			} catch {
				XCTFail(String(describing: error))
			}
		}
		
		// Check that all the rows are returned
		do {
			let obj = User()
			do {
				try obj.findAll()
				XCTAssertEqual(obj.results.rows.count, 200, "Object should have found the all the rows just inserted. Not limited by the default cursor limit.")
				XCTAssertEqual(obj.results.cursorData.totalRecords, 200, "Object should have found the all the rows just inserted")
			} catch {
				XCTFail("findAll error: \(obj.error.string())")
			}
		}
	}
	

	/* =============================================================================================
	Test array set & retrieve
	============================================================================================= */
	func testArray() {
		let obj = User()
		obj.stringarray = ["a", "b", "zee"]

		do {
			try obj.save {id in obj.id = id as! Int }
		} catch {
			XCTFail(String(describing: error))
		}

		let obj2 = User()

		do {
			try obj2.get(obj.id)
			try obj.delete()
			try obj2.delete()
		} catch {
			XCTFail(String(describing: error))
		}
		XCTAssert(obj.id == obj2.id, "Object not the same (id)")
		XCTAssert(obj.stringarray == obj2.stringarray, "Object not the same (stringarray)")
	}
    
    func testNumericType() {
        var theNumeric = PostgresNumeric(12, 4)
        print(theNumeric.value)
        theNumeric.value = 0.0333
        theNumeric += 0.03
        print(theNumeric.stringValue)
        XCTAssert("00000000.0633" == theNumeric.stringValue)
    }
	
    /* =============================================================================================
     parseRows (JSON Aggregation)
     ============================================================================================= */
    func testJsonAggregation() {
        
        // In the parseRows function we changed to cast into either [String:Any] type, OR [[String:Any]] type as aggregated JSON type.
        
        let encodedJSONArray = "[{\"id\":\"101\",\"name\":\"Pushkar\",\"salary\":\"5000\"}, {\"id\":\"102\",\"name\":\"Rahul\",\"salary\":\"4000\"},{\"id\":\"103\",\"name\":\"tanveer\",\"salary\":\"56678\"}]"
        
        do {
            let decodedJSONArray    = try encodedJSONArray.jsonDecode()
            
            if decodedJSONArray as? [[String:Any]] == nil {
                XCTAssert(false, "Failed to cast decoded JSON to array of type [String : Any]")
            }
            
        } catch {
            XCTFail("Failed to decode array of JSON.")
        }
        
        let encodedJSON = "{\"id\":\"101\",\"name\":\"Pushkar\",\"salary\":\"5000\"}"
        
        do {
            let decodedJSON         = try encodedJSON.jsonDecode()
            
            if decodedJSON as? [String:Any] == nil {
                XCTAssert(false, "Failed to cast decoded JSON into [String:Any] type.")
            }
        } catch {
            XCTFail("Failed to decode JSON.")
        }
    
    }

	static var allTests : [(String, (PostgresStORMTests) -> () throws -> Void)] {
		return [
			("testSaveNew", testSaveNew),
			("testSaveUpdate", testSaveUpdate),
			("testSaveCreate", testSaveCreate),
			("testGetByPassingID", testGetByPassingID),
			("testGetByID", testGetByID),
			("testGetByPassingIDtooLarge", testGetByPassingIDtooLarge),
			("testGetByPassingIDnoRecord", testGetByPassingIDnoRecord),
			("testGetBySettingIDnoRecord", testGetBySettingIDnoRecord),
			("testCheckDeleteSQL", testCheckDeleteSQL),
			("testFind", testFind),
			("testFindAll", testFindAll),
			("testArray", testArray),
            ("testJsonAggregation", testJsonAggregation),
            ("testNewModelStructure", testNewModelStructureWithAuditUserId)
		]
	}

}
