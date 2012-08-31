# ABGrid.js

## Awesome Backbone Grid

### Introduction

This is our first open source project, to make our work on an internal project for the company also available to the outter world. During our development of this internal tool, we're in a need to find a javascript grid component to use but we couldn't find a simple one meet below requirements:

* Integrate with Backbone.js
* Support custom format of each cell in the grid
* Support in-place editing
* Support custom in-place editors
* Support drag-drop change columns (both order and width)
* Support drag-drop re-arrange the row display order
* Support size-to-content for each row
* Support paging (client side)

We're trying out best to fullfil above requirements.

### Usage

#### Model

To properly use this grid with backbone, you'll need to prepare two *Backbone.Collection*s :

* columns
* rows

both of them should be instance of *Backbone.Collection*. For example:

    var columns = new Backbone.Collection([
        {name: 'First Name', field: 'firstName', type: 'string'},
        {name: 'Last Name', field: 'lastName', type: 'string'}
    ]);

    var rows = new Backbone.Collection([
        {firstName: 'Tyrael', lastName: 'Tong'},
        {firstName: 'Eric', lastName: 'Yang'}
    ]);

Let's take a more in-depth look at how to define a column. A column definition, consists of a **name**, **field**, and **type**. Those attributes are required to use ABGrid.

**name** is the title displayed on the column headers, and **field** is the attribute name for the corresponding data on the row. Take above example, the first column has _firstName_ as **field**, so the cell value for that row is getting like:

    var cellValue = row.get('firstName');

There're some additional attributes you can set on a column definition, below is a list(with examples):

* **width**: 50px (the width for this column. if not set, then the column width will be 'auto')
* **align**: 'center' | 'left' | 'right' (how to align the header, and the cells forn this column)
* **hidden**: true | false (hide this column or not)
* **required**: true | false (whether this is a requied column)

### Contributors

Tyrael Tong <tyraeltong@gmail.com>

Eric Yang <muyifeng1988@gmail.com>
