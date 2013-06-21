/* AssignmentClient :: {
  progress: Number,
  current: Number,
  name: String,
  description: String,
  pieces: Array<PieceClient>
}
*/

//    { resource: Resource<Instance<a>> }
// *  (a * Instance<a> -> Client<a>)
// -> Evt<Client<a>>
function loadResource(spec, merge) {

}

// DefinitionSpec -> DefinitionClient
function loadDefinition(definitionSpec) {

}

// CheckBlockSpec -> CheckBlockClient
function loadCheckBlock(checkBlockSpec) {

}

// HeaderSpec -> HeaderClient
function loadHeader(headerSpec) {

}
 
// FunctionSpec * FunctionInstance -> FunctionClient
function mergeFunction(functionSpec, functionInstance) {

}

// FunctionSpec -> FunctionClient
function loadFunction(functionSpec) {

}

// PieceSpec * PieceInstance -> PieceClient
function mergePiece(pieceSpec, pieceInstance) {

}

// PieceSpec -> PieceClient
function loadPiece(piece) {

}

// AssignmentSpec * AssignmentInstance -> AssignmentClient
function mergeAssignment(assignmentSpec, assignmentInstance) {

}

// Resource<AssignmentSpec> -> AssignmentClient
function loadAssignment(assignmentResource) {

}

