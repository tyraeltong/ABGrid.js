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
    'click table.abgrid' : 'focusOnTable'
    'keydown #focusSink' : 'handleKeypress'

  defaultGridOptions:
    enableSorting: true
    enablePaging: true
    enableColumnReorder: false
    enableRowReordering: false
    enableCellNavigation: true
    editable: true
    enableAddRow: false
    enableDeleteRow: false

  initialize: (options) =>
    @columns = options.columns # should be a Backbone.Collection
    @rows = options.rows # should be a Backbone.Collection
    @rows.bind 'change', @onRowChanged
    @rows.bind 'add', @onRowAdded
    @rows.bind 'remove', @onRowRemoved

    @activeEditor = null
    @gridOptions = $.extend {}, @defaultGridOptions, options.gridOptions

    @headView = new ABGrid.HeadView {model: @columns, gridOptions: @gridOptions}
    @bodyView = new ABGrid.BodyView {model: @rows, columns: @columns, gridOptions: @gridOptions}

  onRowRemoved: (e) =>
    id = "r" + e.cid
    elem = @$('tr#' + id)
    elem.fadeOut()

  onRowAdded: (e) =>
    gridRow = new ABGrid.RowView {model: e, columns: @columns, gridOptions: @gridOptions}
    gridRow.render()
    @$('tbody').append $(gridRow.el).hide()
    $(gridRow.el).fadeIn()

  onRowChanged: (e) =>
    console.log 'row changed'
    console.log @tdIdx
    id = "r" + e.cid
    gridRow = new ABGrid.RowView {model: e, columns: @columns, gridOptions: @gridOptions}
    @$('tr#' + id).replaceWith gridRow.render().el
    @$('tr#' + id).effect('highlight', {color: 'yellow'}, 500)

    # restore selection status
    $(@$('tbody tr')[@trIdx - 1]).addClass('active')
    $(@$('tr#' + id).children()[@tdIdx - 1]).addClass('active')
    @focusOnTable()
  render: =>
    $(@el).html @template()

    @headView.render()
    @$('thead').append @headView.el
    @bodyView.render()
    @$('table').append @bodyView.el
    @

  focusOnTable: (e) =>
    unless @activeEditor
      @$('#focusSink')[0].focus()
      console.log '#focusOnTable'

  handleKeypress: (e) =>
    handled = e.isImmediatePropagationStopped()

    if (!handled)
      tbody = @$('tbody')
      @tr = @$('tr.active')
      @td = @$('td.active')
      @trIdx = tbody.children().index(@tr)
      @tdIdx = @tr.children().index(@td)
      @rowCount = tbody.children().length
      @colCount = @tr.children().length

      if (!e.shiftKey && !e.altKey && !e.ctrlKey)
        if e.which == 27
          # cancel key, should cancel editor if it's active
          if @activeEditor
            @td.empty()
            @td.append $(@previousTdHtml)
            delete @activeEditor
            @activeEditor = null
            @focusOnTable()
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
        else if (e.which == 9) # tab key pressed
          if @activeEditor
            value = @activeEditor.serializeValue()
            @tdIdx = @tdIdx + 1
            if @tdIdx > @colCount
              @tdIdx = 0
              @trIdx = @trIdx + 1
            @activeEditor.row.set(@activeEditor.column.get('field'), value)
            delete @activeEditor
            @activeEditor = null
            @focusOnTable()
          else
            @navigateNext()
        else if (e.which == 13)
          # enter key pressed, should activate the editor, or save changes
          # one exception: if the editor is textare which need to absorb
          # enter key, what shall we do?
          if @activeEditor
            value = @activeEditor.serializeValue()
            @activeEditor.row.set(@activeEditor.column.get('field'), value)
            delete @activeEditor
            @activeEditor = null
            @focusOnTable()
          else
            if @gridOptions.editable
              @handleEditable()
            # if (currentEditor)
            #   // adding new row
            #   if (activeRow === getDataLength()) {
            #     navigateDown();
            #   }
            #   else {
            #     commitEditAndSetFocus();
            #   }
            # } else {
            #   if (getEditorLock().commitCurrentEdit()) {
            #     makeActiveCellEditable();
            #   }
            # }
        else
          return
      else if (e.which == 9 && e.shiftKey && !e.ctrlKey && !e.altKey)
        if @activeEditor
          @td.empty()
          @td.append $(@previousTdHtml)
          delete @activeEditor
          @activeEditor = null
        @navigatePrev()
      else
        return

    e.stopPropagation()
    e.preventDefault()
    # try
    #   e.originalEvent.keyCode = 0
    # catch (error)

  handleEditable: =>
    column =  @columns.at(@tdIdx - 1)
    row = @rows.at(@trIdx - 1)
    @activeEditor = @getEditor(column, row)
    @previousTdHtml = @td.html()
    @td.empty()
    @td.append @activeEditor.el
    $(@activeEditor.el).select()

  getEditor: (column, row) =>
    editView = new ABGrid.EditView {column: column, row: row, parent: @}
    editView.render()
    editView

  navigateRight: ->
    if !(@trIdx == @rowCount && @tdIdx == @colCount)
      @td.removeClass('active')
      if @tdIdx < @colCount
        @td.next().addClass('active')
      else if @tdIdx = @colCount
        @tr.removeClass('active')
        @tr.next().addClass('active')
        @tr.next().children().first().addClass('active')

  navigateLeft: ->
    if !(@trIdx == 1 && @tdIdx == 1)
      @td.removeClass('active')
      if @tdIdx > 1
        @td.prev().addClass('active')
      else if @tdIdx == 1
        @tr.removeClass('active')
        @tr.prev().addClass('active')
        @tr.prev().children().last().addClass('active')

  navigateUp: ->
    if @trIdx != 1
      @td.removeClass('active')
      @tr.removeClass('active')
      @tr.prev().addClass('active')
      @tr.prev().children().eq(@tdIdx-1).addClass('active')

  navigateDown: ->
    if @trIdx != @rowCount
      @td.removeClass('active')
      @tr.removeClass('active')
      @tr.next().addClass('active')
      @tr.next().children().eq(@tdIdx-1).addClass('active')

  navigateNext: ->
    @navigateRight()

  navigatePrev: ->
    @navigateLeft()

class ABGrid.HeadView extends Backbone.View
  tagName: 'tr'
  template: _.template '
    <th class="abgrid-header"><a class="abgrid-header-link" href="#"><%= name %></a></th>
  '

  initialize: (options) =>
    @gridOptions = options.gridOptions
    @model.bind 'change', @render
    @model.bind 'add', @render
    @model.bind 'remove', @render

  render: =>
    _.each @model.models, (column) =>
      # render a column
      $(@el).append @template(column.toJSON())
    @
class ABGrid.BodyView extends Backbone.View
  tagName: 'tbody'
  initialize: (options) =>
    @columns = options.columns
    @gridOptions = options.gridOptions
  render: =>
    $(@el).empty()
    _.each @model.models, (row) =>
      rowView = new ABGrid.RowView({model: row, columns: @columns, gridOptions: @gridOptions})
      rowView.render()
      $(@el).append rowView.el
    @

class ABGrid.RowView extends Backbone.View
  tagName: 'tr'
  template: _.template '
    <td><%= value %></td>
  '
  events:
    'click td' : 'clickCell'

  initialize: (options) =>
    @columns = options.columns
    @gridOptions = options.gridOptions
  render: =>
    rowHtmlArray = []
    _.each @columns.models, (col) =>
      value = @model.get(col.get('field'))

      # cell formatter here
      formatter = null
      if col.get('formatter')
        formatter = col.get('formatter')
      else if @gridOptions.formatterFactory
        formatter = @gridOptions.formatterFactory.getFormatter(col)

      if formatter
        value = formatter(value, col, @model)

      rowHtmlArray.push @template({value: value})
    rowHtml = rowHtmlArray.join '' # <td>a</td><td>b</td>
    $(@el).append rowHtml
    $(@el).attr('id', "r" + @model.cid)
    @
  clickCell: (e) ->
    $(@.el).parent().find('tr').removeClass('active')
    $(@.el).parent().find('td').removeClass('active')
    $(e.target).closest('td').addClass('active')
    $(e.target).closest('tr').addClass('active')

  getEditor: (column) ->

class ABGrid.EditView extends Backbone.View
  tagName: 'input'
  events:
    'keydown': 'handleKeyDown'

  # handleKeyDown
  #   when the editor is active, it'll get all the key press event
  #   We don't need to do anything special except for:
  #     - esc key pressed : this shall inform the parent to remove the editor
  #     - enter key pressed: this shall first set the value back to the model and then inform the parent to remove the editor
  #     - tab key pressed: this is the same with enter key pressed plus inform parent move to next
  handleKeyDown: (e) =>
    @parent.handleKeypress e
  initialize: (options) =>
    @column = options.column
    @row = options.row
    @parent = options.parent

  render: =>
    $(@el).css({width: '100%', height: '100%'})
    @

  serializeValue: =>
    $(@el).val()