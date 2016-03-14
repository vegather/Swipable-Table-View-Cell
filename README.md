# Swipable-Table-View-Cell

## Demo
![Gif](http://imgur.com/CDEFFBJ.gif)

## Instructions

A subclass of UITableViewCell that makes it possible to swipe left or right on an item to check it off, or remove it. Kind of like how Apple's Mail app works. You can set up your cells like you normally would in your Storyboard, just remember to set SwipableTableViewCell as your class, like this:

![Screenshot](http://imgur.com/Wj76KcD.png)


When you want to receive the swipe actions, just set yourself (your UIViewController typically) as the delegate of the cell. The easiest place to do this is probably in `tableView:cellForRowAtIndexPath:`. You will then receive callbacks on a protocol that looks like this:

```
protocol SwipableTableViewCellDelegate {
    func swipableTableViewCellDidAcceptWithCell(cell: UITableViewCell)
    func swipableTableViewCellDidDeclineWithCell(cell: UITableViewCell)
}
```

This includes the cell that received the swipe so it's quite easy to figure out the index path. An implementation could look like this:

```
func swipableTableViewCellDidAcceptWithCell(cell: UITableViewCell) {
        if let indexPath = tableView.indexPathForCell(cell) {
            // Update your model layer here
        }
    }
```
