Path = require 'path'
FS   = require 'fs'

EsPrima    = require 'esprima'
EsTraverse = require 'estraverse'
ASTtypes   = require 'ast-types'

Encoder = require '../encoder'
Node    = require '../node'

Code = FS.readFileSync Path.join(__dirname, "decoder#{ﬁ.path.core.ext}"), ﬁ.conf.charset
AST  =
	build : ASTtypes.builders
	type  : ASTtypes.namedTypes

module.exports = class

	keyFound : false
	lenFound : false
	encoder  : null
	names    : {}

	constructor: (@encoder)->

	getAST: ->
		# Parse decoder code, removing the wrapping function generated by coffeescript
		code = EsPrima.parse(Code).body.shift().expression

		# Traverse and replace every identifier starting with an underscore
		# with a generated key
		EsTraverse.replace code, enter:(_node, _parent)=>

			node = new Node(_node, _parent)
			name = node.getName()

			# replace the key declaration with encoder's full key.
			if (not @keyFound or not @lenFound) and node.isAssignment()
				left = new Node(node.getProp('left'), node.getParent())
				if left.isMember()
					left = new Node(left.getProp('property'), left)
					if left.isIdentifier()

						if left.getName() is '_full'
							_node.right = AST.build.literal(@encoder.full)
							@keyFound = true
							return _node

						if left.getName() is '_length'
							@lenFound = true
							_node.right = AST.build.literal(@encoder.length)
							return _node

			if not node.isIdentifier() or not (name[0] is '_' and name.length > 1)
				return _node

			@names[name] = '_' + @encoder.generate() if not @names[name]
			return AST.build.identifier @names[name]


		# Wrap the class inside a 'new' and an iife
		thiz = AST.build.identifier 'this'
		call = AST.build.identifier 'call'
		func = AST.build.memberExpression(code.callee, call, false)

		return AST.build.newExpression AST.build.callExpression(func, [thiz]), []