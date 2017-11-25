//
//  Update.swift
//  PostgresStORM
//
//  Created by Jonathan Guthrie on 2016-09-24.
//
//

import StORM
import PerfectLogger
import Foundation

/// Extends the main class with update functions.
extension PostgresStORM {

	/// Updates the row with the specified data.
	/// This is an alternative to the save() function.
	/// Specify matching arrays of columns and parameters, as well as the id name and value.
	@discardableResult
	public func update(cols: [String], params: [Any], idName: String, idValue: Any) throws -> Bool {

		var paramsString = [String]()
		var set = [String]()
		for i in 0..<params.count {
            let param = String(describing: params[i])
            
            if param == "modified" {
                paramsString.append(param)
                set.append("\"\(String(describing: Int(Date().timeIntervalSince1970)))\" = $\(i+1)")
            } else if param == "created" {
                // DO NOTHING:
            } else {
                paramsString.append(param)
                set.append("\"\(cols[i].lowercased())\" = $\(i+1)")
            }
		}
        
		paramsString.append(String(describing: idValue))

		let str = "UPDATE \(self.table()) SET \(set.joined(separator: ", ")) WHERE \"\(idName.lowercased())\" = $\(params.count+1)"

		do {
			try exec(str, params: paramsString)
		} catch {
			LogFile.error("Error msg: \(error)", logFile: "./StORMlog.txt")
			self.error = StORMError.error("\(error)")
			throw error
		}

		return true
	}

	/// Updates the row with the specified data.
	/// This is an alternative to the save() function.
	/// Specify a [(String, Any)] of columns and parameters, as well as the id name and value.
	@discardableResult
	public func update(data: [(String, Any)], idName: String = "id", idValue: Any) throws -> Bool {

		var keys = [String]()
		var vals = [String]()
		for i in 0..<data.count {
            
            // Automatic modified date:
            if data[i].0.lowercased() == "modified" {
                keys.append(data[i].0.lowercased())
                vals.append(String(describing: Int(Date().timeIntervalSince1970)))
            } else if data[i].0.lowercased() == "created" {
                // DO NOTHING ON UPDATE FOR automatic created date field:
            } else {
                keys.append(data[i].0.lowercased())
                vals.append(String(describing: data[i].1))
            }
        
		}
		do {
			return try update(cols: keys, params: vals, idName: idName, idValue: idValue)
		} catch {
			LogFile.error("Error msg: \(error)", logFile: "./StORMlog.txt")
			throw StORMError.error("\(error)")
		}
	}

}
