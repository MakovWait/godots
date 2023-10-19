static func by_type(type):
	return func(bucket: Array, opt):
		for x in bucket:
			if is_instance_of(x, type):
				return opt.found(x)
		return opt.not_found()
