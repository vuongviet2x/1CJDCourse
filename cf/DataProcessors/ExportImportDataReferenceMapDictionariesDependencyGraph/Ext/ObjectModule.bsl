#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables


Var CurGraph; // See NewGraph - Value table that stores graph vertices and edges. 

Var White; // Number - Constant that denotes the white color.

Var Gray; // Number - Constant that denotes the gray color.

Var Black; // Number - Constant that denotes the black color.

#EndRegion

#Region Internal

// Adds a vertex matching the metadata object to the graph.
//
// Parameters:
//  MetadataObjectName - String - a metadata object name matching the graph vertex to be added.
//  OnlyInAbsenceOf - Boolean - if False, an exception will be generated
//    when trying to add a non-unique value. Otherwise, an attempt to add a non-unique
//    value will be ignored.
//
Procedure AddVertex(Val MetadataObjectName, Val OnlyInAbsenceOf = True) Export
	
	MetadataObject = MetadataObject(MetadataObjectName);
	AlreadyExists = (Vertex(MetadataObject, False) <> Undefined);
	
	If AlreadyExists Then
		
		If OnlyInAbsenceOf Then
			Return;
		Else
			Raise NStr("ru = 'Попытка дублирования.';
									|en = 'Duplication attempt.';");
		EndIf;
		
	Else
		
		Count_ = CurGraph; // See NewCount_
		Vertex = Count_.Add(); 
		Vertex.UUID = New UUID;
		Vertex.MetadataObject = MetadataObject;
		Vertex.Ribs = New Array;
		
	EndIf;
	
EndProcedure

// Adds an edge connecting vertices to the graph.
//
// Parameters:
//  MetadataObjectName1 - MetadataObject - matches the first vertex connected by the edge.
//  MetadataObjectName2 - MetadataObject - matches the second vertex connected by the edge.
//
Procedure AddEdge(Val MetadataObjectName1, Val MetadataObjectName2) Export
	
	MetadataObject1 = MetadataObject(MetadataObjectName1);
	MetadataObject2 = MetadataObject(MetadataObjectName2);
	
	Vertex1 = Vertex(MetadataObject1);
	Vertex2 = Vertex(MetadataObject2);
  
	Vertex1.Ribs.Add(Vertex2.UUID);
	Vertex1.NumberOfEdges = Vertex1.NumberOfEdges + 1;
	
EndProcedure

// Executes topological sorting of graph vertices and returns the sorting result.
//
// Returns:
//  Array of MetadataObject - an array of metadata objects sorted in such a way that
//    metadata objects matching vertices, for which edges were added to other
//    vertices, go in the array before metadata objects matching vertices,
//    which were added as edges to other vertices.
//
Function TopologicalSorting() Export
	
	// Initially, all vertices are "white"
	For Each Vertex In CurGraph Do
		Vertex.Color = White;
	EndDo;
	
	SortingResult = New Array();
	
	For Each Vertex In CurGraph Do
		
		// From each vertex perform iteration in depth
		DepthFirstSearch(Vertex, SortingResult);
		
	EndDo;
	
	Return SortingResult;
	
EndFunction

#EndRegion

#Region Private

// Returns a graph value table.
// Vertices are stored as value table rows, edges are stored as a value of one of the columns. 
// 
// Returns:
// 	ValueTable - Details.:
//  * UUID - UUID - graph vertices.
//  * MetadataObject - MetadataObject - a metadata object of the graph vertex.
//  * Ribs - Array of UUID - an array of the graph edges, UUID type values are used
//      as elements of the array. These values match the tabular section
//      rows describing other vertices of the graph.
//  * NumberOfEdges - Number - a number of edges specified for the current vertex.
//  * Color - Number - Stores the color of the current vertex of the graph (see the LocalVariables module area).
//
Function NewCount_()

	Count_ = New ValueTable;
	Count_.Columns.Add("UUID", New TypeDescription("UUID"));
	Count_.Columns.Add("MetadataObject");
	Count_.Columns.Add("Ribs", New TypeDescription("Array"));
	Count_.Columns.Add("NumberOfEdges", New TypeDescription("Number"));
	Count_.Columns.Add("Color", New TypeDescription("Number"));
	Count_.Indexes.Add("UUID");
	
	Return Count_;
		
EndFunction

// Returns a metadata object by its full name, if there is no object in the current
// configuration, an exception is generated.
//
// Parameters:
//  FullName - String - Full name of a metadata object.
//
// Returns:
//   MetadataObject - a metadata object by full name.
//
Function MetadataObject(Val FullName)
	
	MetadataObject = Metadata.FindByFullName(FullName);
	If MetadataObject = Undefined Then
		
		Raise StrTemplate(NStr("ru = 'В текущей конфигурации отсутствует объект метаданных %1, присутствующих в файле данных.';
										|en = 'Metadata object %1 existing in the data file is missing in the current configuration.';"),
			FullName);
		
	EndIf;
	
	Return MetadataObject;
	
EndFunction

// Returns a  row of a value table describing a graph that matches the specified
// metadata object.
//
// Parameters:
//  MetadataObject - MetadataObject - a metadata object
//  ExceptionInAbsenceOf - Boolean - an exception generation flag when the specified
//    metadata object is not missing on the vertices of the current graph.
//
// Returns:
//  ValueTableRow - Row of the CurGraph value table:
//  * UUID - UUID - graph vertices.
//  * MetadataObject - MetadataObject - a metadata object of the graph vertex.
//  * Ribs - Array of UUID - an array of graph edges.
//  * NumberOfEdges - Number - a number of edges specified for the current vertex.
//  * Color - Number - Color of the current vertex of the graph (see the LocalVariables module area).
//  Undefined - If the specified MetadataObject is missing in the current graph and ExceptionIfAbsent = False.
//
Function Vertex(Val MetadataObject, Val ExceptionInAbsenceOf = True)
	 
	FilterParameters = New Structure;
	FilterParameters.Insert("MetadataObject", MetadataObject);
	
	Vertexes = CurGraph.FindRows(FilterParameters);

	If Vertexes.Count() = 1 Then
		
		Return Vertexes.Get(0);
		
	ElsIf Vertexes.Count() = 0 Then
		
		If ExceptionInAbsenceOf Then
			
			Raise StrTemplate(NStr("ru = 'В графе отсутствует вершина для объекта метаданных %1.';
											|en = 'There is no vertex for the %1 metadata object in the column.';"),
				MetadataObject.FullName());
			
		Else
			
			Return Undefined;
			
		EndIf;
		
	Else
		
		Raise StrTemplate(NStr("ru = 'Нарушение уникальности граф для объекта метаданных %1.';
										|en = 'Unique column violation for metadata object %1.';"),
			MetadataObject.FullName());
		
	EndIf;
	
EndFunction

// Executes a depth search upon topological sorting.
//
// Parameters:
//  Vertex - ValueTableRow - a row of the CurrentGraph value table,
//  SortingResult - Array of MetadataObject - a result of the topological sorting.
//
Procedure DepthFirstSearch(Vertex, SortingResult)
	
	// If you enter the gray vertex, a cycle is found, topological sorting is impossible
	If Vertex.Color = Gray Then
		
		Raise NStr("ru = 'Рекурсивная зависимость.';
								|en = 'Recursive dependence.';");
		
	ElsIf Vertex.Color = White Then
		
		// Upon entering the vertex, making it gray
		Vertex.Color = Gray;
		
		// From each vertex perform iteration in depth
		For Each Edge In Vertex.Ribs Do
			DepthFirstSearch(CurGraph.Find(Edge, "UUID"), SortingResult);
		EndDo;
		
		// When exiting the vertex, make it "black"
		Vertex.Color = Black;
		// And put it to the stack
		SortingResult.Add(Vertex.MetadataObject);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Initialize

CurGraph = NewCount_();

White = 1;
Gray = 2;
Black = 3;

#EndRegion

#EndIf