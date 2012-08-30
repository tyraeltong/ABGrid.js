window.ABGrid = {}

class ABGrid.GridView extends Backbone.View
  template: _.template '
    <table class="abgrid">
      <thead></thead>
    </table>
    '
  initialize: (options) =>
    @columns = options.columns # should be a Backbone.Collection
    @rows = options.rows # should be a Backbone.Collection
    @rows.bind 'change', @renderRows
    @rows.bind 'add', @renderRows
    @rows.bind 'remove', @renderRows

    @gridOptions = options.gridOptions
    @headView = new ABGrid.HeadView {model: @columns, gridOptions: @gridOptions}
    @bodyView = new ABGrid.BodyView {model: @rows, columns: @columns, gridOptions: @gridOptions}

  renderRows: =>
    @$('tbody').remove()
    @bodyView.render()
    @$('table').append @bodyView.el

  render: =>
    $(@el).html @template()

    @headView.render()
    @$('thead').append @headView.el
    @bodyView.render()
    @$('table').append @bodyView.el

    @

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
    @model.bind 'add', @render
    @model.bind 'remove', @render
    @model.bind 'change', @render
  render: =>
    $(@el).empty()
    _.each @model.models, (row) =>
      rowView = new ABGrid.RowView({model: row, columns: @columns})
      rowView.render()
      $(@el).append rowView.el
    @

class ABGrid.RowView extends Backbone.View
  tagName: 'tr'
  template: _.template '
    <td><%= value %></td>
  '
  initialize: (options) =>
    @columns = options.columns
  render: =>
    rowHtmlArray = []
    _.each @columns.models, (col) =>
      value = @model.get(col.get('field'))
      # custom formatter here
      rowHtmlArray.push @template({value: value})
    rowHtml = rowHtmlArray.join '' # <td>a</td><td>b</td>
    $(@el).append rowHtml
    @

class ABGrid.EditView extends Backbone.View