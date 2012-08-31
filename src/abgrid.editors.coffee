window.ABGrid.Editors ||= {}

class ABGrid.Editors.CommonEditor
  constructor: (args) ->
    @input = null
    @defaultValue = null
    @args = args
    @init()
  init: =>
    @input = $(@editorHtml())
      .appendTo(@args.container)
      .bind("keydown.nav", (e) ->
        if e.keyCode == $.ui.keyCode.LEFT || e.keyCode == $.ui.keyCode.RIGHT
          e.stopImmediatePropagation()
      ).focus()
      .select()
    @bindEvent()
  editorHtml: =>
    "<input type='text' class='editor-text'/>"
  getDefaultValue: (item) =>
    @defaultValue = item.get(@args.column.field) || ""
    @defaultValue
  destroy: =>
    @input.remove()
  focus: =>
    @input.focus()
  getValue: =>
    @input.val()
  setValue: (val) =>
    @input.val(val)
  loadValue: (item) =>
    @getDefaultValue(item)
    @input.val(@defaultValue)
    @input[0].defaultValue = @defaultValue
    @input.select()
  serializeValue: =>
    @input.val()
  applyValue: (item, state) =>
    item.set(@args.column.field, state)
  isValueChanged: =>
    (!(@input.val() == "" && @defaultValue == null)) && (@input.val() != @defaultValue)
  validate: =>
    if (@args.column.validator)
      validationResults = @args.column.validator(@input.val())
      if !validationResults.valid
        return validationResults
    return {
      valid: true
      msg: null
    }
  bindEvent: =>
    false

class ABGrid.Editors.TextEditor extends ABGrid.Editors.CommonEditor

class ABGrid.Editors.BooleanEditor extends ABGrid.Editors.CommonEditor
  editorHtml: =>
    "<input type='checkbox' value='true' class='editor-checkbox' hideFocus />"

  getDefaultValue: (item) =>
    @defaultValue = item.get(@args.column.field)
    @defaultValue
  loadValue: (item) =>
    @getDefaultValue(item)
    if @defaultValue
      @input.attr('checked', 'checked')
    else
      @input.removeAttr('checked')
  serializeValue: =>
    if @input.attr("checked")
      true
    else
      false
  isValueChanged: =>
    @input.attr('checked') != @defaultValue
  validate: =>
    return {
      valid: true
      msg: null
    }

class ABGrid.Editors.NumberEditor extends ABGrid.Editors.CommonEditor
  editorHtml: =>
    "<input type='number' class='editor-number' />"
  getDefaultValue: (item) =>
    @defaultValue = item.get(@args.column.field)
  serializeValue: =>
    parseInt(@input.val(), 10) || 0
  validate: =>
    if isNaN @input.val()
      return {
        valid: false
        msg: "Please enter a valid number"
      }

    return {
      valid: true,
      msg: null
    }
  bindEvent: =>
    @input.bind 'keydown', (e)=>
      # console.log e.keyCode
      key = e.charCode || e.keyCode || 0
      (key == 8 || key == 9 || key == 46 || (key >= 37 && key <= 40) || (key >= 48 && key <= 57) || (key >= 96 && key <= 105))

class ABGrid.Editors.DateEditor extends ABGrid.Editors.CommonEditor
