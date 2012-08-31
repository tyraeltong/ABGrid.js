window.ABGrid = {}

class ABGrid.GridView extends Backbone.View
  className: 'grid'
  template: _.template '
    <div id="focusSink" class="sink" tabindex="0" style="position:fixed;width:0;height:0;top:0;left:0;outline:0"></div>
    <table class="abgrid">
      <thead></thead>
    </table>
    '

  events:
    'click table.abgrid' : 'handleClick'
    'dblclick table.abgrid' : 'handleDblClick'
    'keydown #focusSink' : 'handleKeypress'
    'focusout table.abgrid' : "onFocusOutFromGrid"
  defaultGridOptions:
    enableSorting: true
    enablePaging: true
    enableColumnReorder: false
    enableRowReordering: false
    enableCellNavigation: true
    editable: true
    enableAddRow: false
    enableDeleteRow: false

  handleClick: (e) =>
    cell = @getCellFromEvent e
    if cell
      cellView = $(cell).data('cell')
      @activateCell cellView if cellView

  handleDblClick: (e) =>
    cell = @getCellFromEvent e
    if cell
      cellView = $(cell).data('cell')
      @activateEditor cellView if cellView

  initialize: (options) =>
    @columns = options.columns # should be a Backbone.Collection
    @rows = options.rows # should be a Backbone.Collection
    @rows.bind 'change', @onRowChanged
    @rows.bind 'add', @onRowAdded
    @rows.bind 'remove', @onRowRemoved

    @activeEditor = null
    @activeCell = null
    @gridOptions = $.extend {}, @defaultGridOptions, options.gridOptions

    @headView = new ABGrid.HeadView {model: @columns, rows: @rows, gridOptions: @gridOptions}
    @bodyView = new ABGrid.BodyView {model: @rows, columns: @columns, gridOptions: @gridOptions, parent: @}

  # model change event handlers
  onRowRemoved: (e) =>
    id = "r" + e.cid
    elem = @$('tr#' + id)
    elem.fadeOut()

  onRowAdded: (e) =>
    gridRow = new ABGrid.RowView {model: e, columns: @columns, gridOptions: @gridOptions, parent: @}
    gridRow.render()
    @$('tbody').append $(gridRow.el).hide()
    $(gridRow.el).fadeIn()

  onRowChanged: (e) =>
    # note we don't trigger this anymore
    console.log 'row changed'
    console.log @tdIdx
    id = "r" + e.cid
    gridRow = new ABGrid.RowView {model: e, columns: @columns, gridOptions: @gridOptions, parent: @}
    @$('tr#' + id).replaceWith gridRow.render().el
    @$('tr#' + id).effect('highlight', {color: 'yellow'}, 500)

    @focusOnTable()

  render: =>
    $(@el).html @template()

    @headView.render()
    @$('thead').append @headView.el
    @bodyView.render()
    @$('table').append @bodyView.el
    @

  getCellFromEvent: (e) =>
    cell = $(e.target).closest('.ab-cell')
    if !cell.length
      return null
    else
      return cell[0]

  onFocusOutFromGrid: (e) =>
    #@commitCurrentEdit()

  focusOnTable: (e) =>
    unless @activeEditor
      @$('#focusSink')[0].focus()
      console.log '#focusOnTable'
  setupActiveRowColumnData: =>
    @td = $(@activeCell.el)
    @tr = @td.closest('tr')

    tbody = @$('tbody')

    @trIdx = tbody.children().index(@tr)
    @tdIdx = @tr.children().index(@td)
    @rowCount = tbody.children().length
    @colCount = @tr.children().length
  handleKeypress: (e) =>
    console.log "GridView#handleKeypress"
    handled = e.isImmediatePropagationStopped()

    if (!handled)
      @setupActiveRowColumnData()

      if (!e.shiftKey && !e.altKey && !e.ctrlKey)
        if e.which == 27 # esc key
          if @activeEditor
            @cancelCurrentEdit()
        else if (e.which == 37)
          unless @activeEditor
            @navigateLeft()
        else if (e.which == 39)
          unless @activeEditor
            @navigateRight()
        else if (e.which == 38)
          unless @activeEditor
            @navigateUp()
        else if (e.which == 40)
          unless @activeEditor
            @navigateDown()
        else if (e.which == 9) # tab key
          if @activeEditor
            @commitCurrentEdit()
          @navigateNext()
        else if (e.which == 13) # enter key
          if @gridOptions.editable
            if @activeEditor
              @commitCurrentEdit()
            else
              @activateEditor(@activeCell)
        else
          return
      else if (e.which == 9 && e.shiftKey && !e.ctrlKey && !e.altKey)
        if @activeEditor
          @commitCurrentEdit()
        @navigatePrev()
      else
        return

    e.stopPropagation()
    e.preventDefault()
    # try
    #   e.originalEvent.keyCode = 0
    # catch (error)

  activateCell: (cellView) =>
    # if it's already active, or there's an active editor
    # then we do nothing
    unless @activeCell == cellView or @activeEditor
      $(@activeCell.el).removeClass('active') if @activeCell
      @activeCell = cellView
      $(@activeCell.el).addClass('active')
      @focusOnTable()

  activateEditor: (cellView) =>
    if @activeEditor
      if @activeCell == cellView # dbl click on same cell again, do nothing
        return
      else
        @commitCurrentEdit()
        @createEditor(cellView)
    else
      @createEditor(cellView)

  createEditor: (cellView) =>
    @activateCell(cellView)
    @activeEditor = @getEditor(cellView.column, cellView.row)
    # just hide origin content
    $(cellView.el).children().hide()
    $(cellView.el).append @activeEditor.el
    $(@activeEditor.focusElement()).select()

  cancelCurrentEdit: =>
    if @activeEditor
      $(@activeEditor.el).remove()
      # this td/tr is likly be changed by other method
      # so we should change to cancel the editor itself
      delete @activeEditor
      $(@activeCell.el).children().show()
      @activeEditor = null
      @focusOnTable()

  commitCurrentEdit: =>
    if @activeEditor
      value = @activeEditor.serializeValue()
      oldValue = @activeEditor.row.get(@activeEditor.column.get('field'))
      if value == oldValue
        @cancelCurrentEdit()
      else
        @activeEditor.row.set(@activeEditor.column.get('field'), value, {silent: true})
        $(@activeEditor.el).remove()
        delete @activeEditor
        @activeCell.render()
        @activeEditor = null
        @focusOnTable()

  handleEditable: =>
    if @activeEditor
      @commitCurrentEdit()
    else
      column =  @columns.at(@tdIdx)
      row = @rows.at(@trIdx)
      @activeEditor = @getEditor(column, row)
      @previousTdHtml = @td.html()
      @td.empty()
      @td.append @activeEditor.el
      @tr.data('view').editing = true
      @tr.data('view').editingColumn = column
      $(@activeEditor.focusElement()).select()

  getEditor: (column, row) =>
    editView = new ABGrid.Editors.TextAreaEditor {column: column, row: row, parent: @}
    editView.render()
    editView

  navigateRight: ->
    if !(@trIdx >= (@rowCount - 1) && @tdIdx >= (@colCount - 1) )
      if @tdIdx < @colCount - 1
        cell = $(@td.next()).data('cell')
      else if @tdIdx = @colCount - 1
        cell = $(@tr.next().children().first()).data('cell')
      @activateCell(cell)

  navigateLeft: ->
    if !(@trIdx == 0 && @tdIdx == 0)
      if @tdIdx > 0
        cell = @td.prev().data('cell')
      else if @tdIdx == 0
        cell = @tr.prev().children().last().data('cell')
      @activateCell(cell)

  navigateUp: ->
    if @trIdx != 0
      cell = @tr.prev().children().eq(@tdIdx).data('cell')
      @activateCell(cell)

  navigateDown: ->
    if @trIdx != (@rowCount - 1)
      cell = @tr.next().children().eq(@tdIdx).data('cell')
      @activateCell(cell)

  navigateNext: ->
    @navigateRight()

  navigatePrev: ->
    @navigateLeft()

class ABGrid.HeadView extends Backbone.View
  tagName: 'tr'
  template: _.template '
    <th class="abgrid-header"><a class="abgrid-header-link" href="#"><%= name %><i class="icon-sort"></i></a></th>
  '
  events:
    'click a.abgrid-header-link' : 'sortByHeader'

  initialize: (options) =>
    @rows = options.rows
    @gridOptions = options.gridOptions
    @model.bind 'change', @render
    @model.bind 'add', @render
    @model.bind 'remove', @render

  render: =>
    _.each @model.models, (column) =>
      # render a column
      $(@el).append @template(column.toJSON())
    @

  sortByHeader: (e) ->
    i = $(e.target).closest('a').children('i')
    th = $(e.target).closest('th')
    tr = $(e.target).closest('tr')
    thIdx = tr.index(th)

    if i.attr('class') == 'icon-sort'
      console.log "un-sort"
      @sortDown()
    else if i.attr('class') == 'icon-sort-down'
      console.log "sort-down"
    else if i.attr('class') == 'icon-sort-down'
      console.log "sort-up"

  sortDown: =>
    queryEngine = window.queryEngine
    result = queryEngine.createCollection(@rows)

class ABGrid.BodyView extends Backbone.View
  tagName: 'tbody'
  initialize: (options) =>
    @columns = options.columns
    @gridOptions = options.gridOptions
    @parent = options.parent
  render: =>
    $(@el).empty()
    _.each @model.models, (row) =>
      rowView = new ABGrid.RowView({model: row, columns: @columns, gridOptions: @gridOptions, parent: @parent})
      rowView.render()
      $(@el).append rowView.el
    @

class ABGrid.RowView extends Backbone.View
  tagName: 'tr'
  initialize: (options) =>
    @columns = options.columns
    @gridOptions = options.gridOptions
    @parent = options.parent
  render: =>
    width = (100/@columns.models.length)+'%'
    _.each @columns.models, (column) =>
      if column.width
        columnWidth = column.width
      else
        columnWidth = width

      cellView = new ABGrid.CellView {column: column, row: @model, width: width, parent: @parent}
      $(@el).append cellView.render().el

    $(@el).attr('id', "r" + @model.cid)
    # append self to DOM for later use
    $(@el).data('view', @)
    @

class ABGrid.CellView extends Backbone.View
  tagName: 'td'
  className: 'ab-cell'
  initialize: (options) =>
    @column = options.column
    @row = options.row
    @parent = options.parent
    @getFormatter()
    @width = options.width

  getFormatter: =>
    @formatter = null
    if @column.get('formatter')
      @formatter = @column.get('formatter')
    else if @parent.gridOptions.formatterFactory
      @formatter = @parent.gridOptions.formatterFactory.getFormatter(@column)

  render: =>
    value = @row.get @column.get('field')
    if @formatter
      value = @formatter(value, @column, @row)

    $(@el).append value
    $(@el).css {width: @width}
    # append self to DOM for later use
    $(@el).data('cell', @)
    @
