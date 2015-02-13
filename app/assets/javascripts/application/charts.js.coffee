# Color palette
colors = ["#DDDF0D", "#7798BF", "#55BF3B", "#DF5353", "#aaeeee", "#ff0066", "#eeaaee", "#55BF3B", "#DF5353", "#7798BF", "#aaeeee"]

$(document).on 'ready page:load', ->
  $("dl.with-charts").each ->
    $dl  = $ @
    rows = []
    key  = text = null

    # Iterate over definition list
    $dl.find("dt, dd").each (node)->
      text = $(@).text()
      if @tagName=="DT"
        key = text
      else
        rows.push
          color: colors[rows.length % colors.length]
          label: key
          value: parseInt(text)

    # Draw chart
    canvas = $("<canvas width=500 height=300></canvas>").insertAfter $dl
    ctx    = canvas[0].getContext('2d')
    new Chart(ctx).Pie(rows, {})
