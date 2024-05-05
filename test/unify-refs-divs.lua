function Div (div)
  if div.identifier:match '^refs%-' then
    div.attributes['entry-spacing'] = "0"
    return div
  end
end
