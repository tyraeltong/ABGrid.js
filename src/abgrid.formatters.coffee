window.ABGrid ||= {}

class ABGrid.FormatterFactory
  getFormatter: (columnDef) =>
    switch columnDef.get('type')
      when 'string'
        result = @stringFormatter

  stringFormatter: (value, columnDef, dataContext) ->
    "<div>" + value + "</div>"