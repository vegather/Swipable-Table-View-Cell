//
//  TableViewController.swift
//  Swiper
//
//  Created by Vegard Solheim Theriault on 23/07/15.
//  Copyright © 2015 Vegard Solheim Theriault. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController, SwipableTableViewCellDelegate {

    struct DataType {
        let primary: String
        let secondary: String
        var finished: Bool
        
        init(index: Int) {
            self.primary = "Item #\(index)"
            self.secondary = "This is item number \(index)"
            self.finished = false
        }
    }
    
    lazy var data: [DataType] = {
        var temp = [DataType]()
        for i in 0...10000 {
            temp.append(DataType(index: i))
        }
        return temp
        }()


    
    
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SwipingCell", forIndexPath: indexPath) as! SwipableTableViewCell

        let dataForCell = data[indexPath.row]
        
        cell.textLabel?.text = dataForCell.primary
        cell.detailTextLabel?.text = dataForCell.secondary
        cell.delegate = self
        
        if dataForCell.finished {
            cell.textLabel?.alpha = 0.2
            cell.detailTextLabel?.alpha = 0.2
        } else {
            cell.textLabel?.alpha = 1.0
            cell.detailTextLabel?.alpha = 1.0
        }

        return cell
    }
    
    
    
    
    func swipableTableViewCellDidAcceptWithCell(cell: UITableViewCell) {
        let indexPath = tableView.indexPathForCell(cell)!
        
        data[indexPath.row].finished = true
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
    }
    
    func swipableTableViewCellDidDeclineWithCell(cell: UITableViewCell) {
        let indexPath = tableView.indexPathForCell(cell)!
        
        data.removeAtIndex(indexPath.row)
        tableView.beginUpdates()
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        tableView.endUpdates()
    }


}
