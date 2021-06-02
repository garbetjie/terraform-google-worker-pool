${jsonencode({
    type = type == null ? "volume" : lower(type)
    src = src
    target = target
    readonly = readonly == null ? false : readonly
})}