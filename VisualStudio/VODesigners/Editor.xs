//
// Copyright (c) XSharp B.V.  All Rights Reserved.  
// Licensed under the Apache License, Version 2.0.  
// See License.txt in the project root for license information.
//
using System.Collections.Generic
using System.Collections


SEALED CLASS ParseInfo
	EXPORT cName AS STRING
	EXPORT cClass AS STRING
	EXPORT cNameSpace AS STRING
	EXPORT nLine AS INT
	EXPORT nLength AS INT
	EXPORT eType AS EntityType
	EXPORT cModifiers AS STRING
	EXPORT nEndClassLine AS INT
	EXPORT cInherit AS STRING
	EXPORT cRetType AS STRING
	EXPORT aParams AS NameValueCollection
	EXPORT eAccessLevel AS AccessLevel
	EXPORT lStatic AS LOGIC
	EXPORT lPartial AS LOGIC
	CONSTRUCTOR()
		SUPER()
		SELF:cModifiers := ""
		SELF:cInherit := ""
		SELF:cRetType := ""
	RETURN
	METHOD AddParam(cParam AS STRING) AS VOID
		IF SELF:aParams == NULL
			SELF:aParams := NameValueCollection{}
		END IF
		SELF:aParams:Add(cParam , "USUAL")
	RETURN
	METHOD SetParamType(cType AS STRING) AS VOID
		IF SELF:aParams == NULL .or. SELF:aParams:Count == 0 .or. String.IsNullOrEmpty(cType)
			RETURN
		END IF
		SELF:aParams:Set(SELF:aParams:Count - 1 , cType)
	RETURN
	
	METHOD ToString() AS STRING
		LOCAL cRet AS STRING
		LOCAL n AS INT
		IF SELF:eType == EntityType._Access .or. SELF:eType == EntityType._Assign .or. SELF:eType == EntityType._Constructor .or. SELF:eType == EntityType._Destructor .or. SELF:eType == EntityType._Event .or. SELF:eType == EntityType._IVar .or. SELF:eType == EntityType._Method
			cRet := "    "
		ELSE
			cRet := ""
		END IF
		cRet += SELF:cModifiers + " "
		cRet += SELF:eType:ToString() + " "
		cRet += SELF:cName
		IF .not. String.IsNullOrEmpty(SELF:cInherit)
			cRet += " (" + SELF:cInherit + ") "
		END IF
		IF SELF:aParams != NULL
			cRet += "  -  "
			FOR n := 0 UPTO SELF:aParams:Count - 1
				IF n != 0
					cRet += " , "
				END IF
				cRet += SELF:aParams:GetName(n) + " AS " + (STRING)SELF:aParams:GetValue(n)
			NEXT
		END IF
	RETURN cRet
END CLASS


SEALED CLASS CodeManager
	PRIVATE aLines AS List<STRING>

	INTERNAL CONSTRUCTOR(_aLines AS List<STRING>)
		SUPER()
		SELF:aLines := _aLines
	RETURN
	CONSTRUCTOR()
	RETURN

	METHOD DisplayEntities() AS VOID
		LOCAL oInfo AS ParseInfo
		LOCAL cText AS STRING
		LOCAL n AS INT

		VAR aEntities := List<ParseInfo>{}
		VAR aDefines := List<DefineInfo>{}
		
		SELF:Parse(aEntities , aDefines)
		cText := ""
		FOR n := 0 UPTO aEntities:Count - 1
			oInfo := aEntities[n]
			cText += oInfo:eType:ToString()
			cText += e"\t"
			cText += oInfo:cName
			cText += e"\t"
			cText += oInfo:cClass
			cText += e"\t"
			cText += oInfo:nLine:ToString() + "," + oInfo:nLength:ToString()
			cText += e"\r\n"
		NEXT
		System.Windows.Forms.MessageBox.Show(cText , "Entities")
	RETURN

	INTERNAL METHOD Clear() AS VOID
		SELF:aLines:Clear()
	RETURN
	INTERNAL METHOD AddLine(cLine AS STRING) AS VOID
		SELF:aLines:Add(cLine)
	RETURN
	
	INTERNAL METHOD DeleteDefines(aDefines AS List<STRING>) AS VOID
		LOCAL oDefine AS DefineInfo
		LOCAL n , m AS INT
		
		VAR aEntities   := List<ParseInfo>{}
		VAR aOldDefines := List<DefineInfo>{}
		SELF:Parse(aEntities , aOldDefines)
		FOR n := aOldDefines:Count -1 DOWNTO 0
			oDefine := aOldDefines[n]
			FOR m := 0 UPTO aDefines:Count - 1
				IF oDefine:cDefine == aDefines[m]:ToUpper()
					SELF:aLines:RemoveAt(oDefine:nLine)
					EXIT
				ENDIF
			NEXT
		NEXT
	RETURN

	INTERNAL METHOD ReplaceDefines(aDefines AS List<STRING> , aDefineValues AS List<STRING> , lEnd AS LOGIC) AS VOID
		LOCAL oDefine AS DefineInfo
		LOCAL n , m AS INT
		
		VAR aEntities   := List<ParseInfo>{}
		VAR aOldDefines := List<DefineInfo>{}
		SELF:Parse(aEntities , aOldDefines)
		FOR n := aOldDefines:Count -1 DOWNTO 0
			oDefine := aOldDefines[n]
			FOR m := 0 UPTO aDefines:Count - 1
				IF oDefine:cDefine == aDefines[m]:ToUpper()
					SELF:aLines:RemoveAt(oDefine:nLine)
					EXIT
				ENDIF
			NEXT
		NEXT
		FOR n := 0 UPTO aDefines:Count - 1
			IF lEnd
				SELF:aLines:Add("#define " + aDefines[n] + " " + aDefineValues[n])
			ELSE
				SELF:aLines:Insert(n , "#define " + aDefines[n] + " " + aDefineValues[n])
			ENDIF
		NEXT
	RETURN
	
	INTERNAL METHOD FindEntityLine(cName AS STRING , cClass AS STRING , eType AS EntityType) AS INT

        LOCAL oInfo AS ParseInfo
		LOCAL n AS INT
		
		VAR aEntities := List<ParseInfo>{}
		VAR aDefines  := List<DefineInfo>{}
		
		SELF:Parse(aEntities , aDefines)
		cName := cName:ToUpper()
		cClass := cClass:ToUpper()
		FOR n := 0 UPTO aEntities:Count - 1
			oInfo := aEntities[n]
			IF oInfo:eType == eType .and. oInfo:cName:ToUpper() == cName .and. oInfo:cClass:ToUpper() == cClass
				RETURN oInfo:nLine
			ENDIF
		NEXT
	RETURN 0

	INTERNAL METHOD DeleteEntity(cName AS STRING , cClass AS STRING , eType AS EntityType) AS LOGIC
        LOCAL oInfo AS ParseInfo
		LOCAL nLine AS INT
		LOCAL n,m AS INT
		
		VAR aDefines := List<DefineInfo>{}
		VAR aEntities := List<ParseInfo>{}
		
		SELF:Parse(aEntities , aDefines)
		cName := cName:ToUpper()
		cClass := cClass:ToUpper()
		FOR n := 0 UPTO aEntities:Count - 1
			oInfo := aEntities[n]
			IF oInfo:eType == eType .and. oInfo:cName:ToUpper() == cName .and. oInfo:cClass:ToUpper() == cClass
				nLine := oInfo:nLine
				FOR m := 1 UPTO oInfo:nLength
					SELF:aLines:RemoveAt(nLine - 1)
				NEXT
				RETURN TRUE
			ENDIF
		NEXT
	RETURN FALSE

	INTERNAL METHOD DeleteClass(cClass AS STRING) AS LOGIC
		LOCAL oInfo AS ParseInfo
		LOCAL lFound := FALSE AS LOGIC
		LOCAL nLine AS INT
		LOCAL n,m AS INT
		
		VAR aEntities := List<ParseInfo>{}
		VAR aDefines := List<DefineInfo>{}
		
		SELF:Parse(aEntities , aDefines)
		cClass := cClass:ToUpper()
		FOR n := aEntities:Count - 1 DOWNTO 0
			oInfo := aEntities[n]
			IF oInfo:cClass:ToUpper() == cClass
				lFound := TRUE
				IF oInfo:nEndClassLine != 0
					SELF:aLines:RemoveAt(oInfo:nEndClassLine - 1)
				END IF
				nLine := oInfo:nLine
				FOR m := 1 UPTO oInfo:nLength
					SELF:aLines:RemoveAt(nLine - 1)
				NEXT
			ENDIF
		NEXT
	RETURN lFound

	INTERNAL METHOD ReplaceEntity(cName AS STRING , cClass AS STRING , eType AS EntityType , aEntity AS List<STRING>) AS LOGIC
		LOCAL oInfo AS ParseInfo
		LOCAL lProceed := FALSE AS LOGIC
		LOCAL nInsert := 0 AS INT
		LOCAL nLine AS INT
		LOCAL n,m AS INT
		
		VAR aEntities := List<ParseInfo>{}
		VAR aDefines := List<DefineInfo>{}
		
		SELF:Parse(aEntities , aDefines)
		cName := cName:ToUpper()
		cClass := cClass:ToUpper()
		FOR n := 0 UPTO aEntities:Count - 1
			oInfo := aEntities[n]
			IF oInfo:eType == eType .and. oInfo:cName:ToUpper() == cName .and. oInfo:cClass:ToUpper() == cClass
				IF eType == EntityType._Class
					aEntity[0] := oInfo:cModifiers + aEntity[0]
				END IF
				nLine := oInfo:nLine
				FOR m := 1 UPTO oInfo:nLength
					IF SELF:aLines[nLine - 1]:IndexOf("{{%UC%}}") != -1 .or. SELF:aLines[nLine - 1]:IndexOf("//USER CODE") != -1
						EXIT
					ENDIF
					SELF:aLines:RemoveAt(nLine - 1)
				NEXT
				lProceed := TRUE
				nInsert := nLine - 1
				EXIT
			ENDIF
		NEXT
		
		IF !lProceed // Entity not found to replace, try to create from scratch
			DO CASE
			CASE eType == EntityType._Class // Create the class at the end of the file
				lProceed := TRUE
				nInsert := SELF:aLines:Count
				aEntity:Insert(0 , "")
				aEntity:Add("")
				aEntity:Add("END CLASS")
			CASE eType == EntityType._Constructor // Create it, after the class definition
				FOR n := 0 UPTO aEntities:Count - 1
					oInfo := aEntities[n]
					IF oInfo:eType == EntityType._Class .and. oInfo:cName:ToUpper() == cClass .and. oInfo:cClass:ToUpper() == cClass
						lProceed := TRUE
						nInsert := oInfo:nLine + oInfo:nLength - 1
						EXIT
					ENDIF
				NEXT
			CASE eType == EntityType._Access .or. eType == EntityType._Assign .or. eType == EntityType._Method // Create it, at the end of the class
				FOR n := 0 UPTO aEntities:Count - 1
					oInfo := aEntities[n]
					IF oInfo:cClass:ToUpper() == cClass
						lProceed := TRUE
						nInsert := oInfo:nLine + oInfo:nLength - 1
					ENDIF
				NEXT
			END CASE
		ENDIF

		IF lProceed
			FOR n := 0 UPTO aEntity:Count - 1
				SELF:aLines:Insert(nInsert + n, aEntity[n])
			NEXT
		END IF

	RETURN lProceed

	INTERNAL METHOD AddEntity(cName AS STRING , cClass AS STRING , eType AS EntityType , aEntity AS List<STRING>) AS LOGIC
        LOCAL oInfo AS ParseInfo
		LOCAL lProceed:= FALSE  AS LOGIC
		LOCAL nInsert := 0 AS INT
		LOCAL n AS INT
		
		VAR aEntities := List<ParseInfo>{}
		VAR aDefines := List<DefineInfo>{}
		
		SELF:Parse(aEntities , aDefines)
		cName := cName:ToUpper()
		cClass := cClass:ToUpper()
		FOR n := 0 UPTO aEntities:Count - 1
			oInfo := aEntities[n]
			IF oInfo:eType == eType .and. oInfo:cName:ToUpper() == cName .and. oInfo:cClass:ToUpper() == cClass
				RETURN TRUE
			ENDIF
		NEXT
		
		FOR n := 0 UPTO aEntities:Count - 1 // find last entity in class
			oInfo := aEntities[n]
			IF oInfo:cClass:ToUpper() == cClass
				lProceed := TRUE
				nInsert := oInfo:nLine + oInfo:nLength - 1
			ENDIF
		NEXT

		IF lProceed
			FOR n := 0 UPTO aEntity:Count - 1
				SELF:aLines:Insert(nInsert + n, aEntity[n])
			NEXT
		END IF

	RETURN lProceed

	INTERNAL METHOD GetLastClassLine(cClass AS STRING) AS INT
		LOCAL oInfo AS ParseInfo
		LOCAL nLine := 0 AS INT
		LOCAL n AS INT
		
		VAR aEntities := List<ParseInfo>{}
		VAR aDefines := List<DefineInfo>{}
		
		SELF:Parse(aEntities , aDefines)
		cClass := cClass:ToUpper()
		FOR n := 0 UPTO aEntities:Count - 1
			oInfo := aEntities[n]
			IF oInfo:cClass:ToUpper() == cClass
				nLine := oInfo:nLine + oInfo:nLength - 1
			ENDIF
		NEXT
	RETURN nLine

	INTERNAL METHOD GetFirstEntity() AS ParseInfo
		VAR aEntities := List<ParseInfo>{}
		VAR aDefines := List<DefineInfo>{}
		SELF:Parse(aEntities , aDefines)
		IF aEntities:Count != 0
			RETURN aEntities[0]
		END IF
	RETURN NULL
	
	INTERNAL STATIC METHOD ParseEntities(oSource AS IEnumerable) AS IList<ParseInfo>
		LOCAL oManager AS CodeManager
		oManager := CodeManager{}
	RETURN oManager:Parse(oSource , TRUE)

	METHOD Parse(oSource AS IEnumerable , lIntellisense AS LOGIC) AS IList<ParseInfo>
		VAR aEntities := List<ParseInfo>{}
		SELF:Parse(oSource , aEntities , NULL , lIntellisense)
	RETURN aEntities

	PRIVATE METHOD Parse(aEntities AS IList<ParseInfo> , aDefines AS IList<DefineInfo>) AS VOID
		SELF:Parse(SELF:aLines , aEntities , aDefines , FALSE)
	RETURN
    
	PRIVATE METHOD Parse(oSource AS IEnumerable , aEntities AS IList<ParseInfo> , aDefines AS IList<DefineInfo> , lIntellisense AS LOGIC) AS VOID
	
		LOCAL oEnumerator AS IEnumerator
		LOCAL cLine AS STRING
		LOCAL nLine,nLineLen AS INT
		LOCAL cChar,cOldChar AS Char
		LOCAL cRealChar AS Char
		LOCAL cTestChar AS Char
		LOCAL sWord AS System.Text.StringBuilder
		LOCAL cWord,cUpperWord AS STRING
		LOCAL state AS ParseState
		LOCAL lIsBreakChar := FALSE AS LOGIC
		LOCAL lIsSpaceChar := FALSE AS LOGIC
		LOCAL lEscapedWord := FALSE AS LOGIC
		LOCAL lEscapedString := FALSE AS LOGIC
		LOCAL lInEnum := FALSE AS LOGIC
		LOCAL sFoundType AS System.Text.StringBuilder
		LOCAL lNewCommandInLine := FALSE AS LOGIC
		LOCAL lContinueNextLine := FALSE AS LOGIC
		LOCAL lBeforeLexerChange := FALSE AS LOGIC
		LOCAL cEnumType AS STRING
		LOCAL nChar AS INT
		LOCAL cClass AS STRING
		LOCAL oInfo := NULL AS ParseInfo
		LOCAL cModifiers := "" AS STRING
		LOCAL eAccessLevel AS AccessLevel
		LOCAL eLexer AS LexerStep
		LOCAL eStep AS ParseStep
		LOCAL aFields AS List<ParseInfo>
		LOCAL aNameSpaces AS Stack<STRING>
		LOCAL cNameSpace AS STRING
		LOCAL n,n1,n2 AS INT
        eAccessLevel := 0
        eLexer := 0
        eStep := 0

        n := n1 := n2 := 0
		state := parseState{}
		aEntities:Clear()
		IF aDefines != NULL
			aDefines:Clear()
		END IF
		aFields := List<ParseInfo>{}
		
		cNameSpace := ""
		cClass := ""
		aNameSpaces := Stack<STRING>{}
		sWord := System.Text.StringBuilder{20}
		sFoundType := System.Text.StringBuilder{20}

		nLine := 0
		oEnumerator := oSource:GetEnumerator()
		DO WHILE oEnumerator:MoveNext()
			// Line parsing
			cLine := (STRING)oEnumerator:Current
			nLine ++
			nChar := 0
			cChar := ' '
			cOldChar := ' '
			cRealChar := ' '
			nLineLen := cLine:Length
			sWord:Length := 0
			lEscapedWord := FALSE

			IF lContinueNextLine
				lContinueNextLine := FALSE
			ELSE
				state:Reset()
				cModifiers := ""
				sFoundType:Length := 0
				eAccessLevel := AccessLevel.Public
				eStep := ParseStep.None
				aFields:Clear()
				sWord:Length := 0
				cRealChar := ' '
				lEscapedWord := FALSE
			ENDIF
			IF eLexer != LexerStep.BlockComment
				eLexer := LexerStep.None
			END IF
			
			DO WHILE nChar <= nLineLen // one more than chars in line
				
				// Lexing
				cOldChar := cRealChar
				IF cOldChar == ';'
					lNewCommandInLine := FALSE
					lContinueNextLine := TRUE
					IF nChar < nLineLen
						FOR n := nChar UPTO nLineLen - 1
							cTestChar := cLine[n]
							IF cTestChar != ' ' .and. cTestChar != '\t'
								IF cTestChar != '/'  // non-commented code follows
									lNewCommandInLine := TRUE
									lContinueNextLine := FALSE
								END IF
								EXIT
							END IF
						NEXT
					ENDIF
					IF lNewCommandInLine
						lNewCommandInLine := FALSE
						state:Reset()
						cModifiers := ""
						sFoundType:Length := 0
						eAccessLevel := AccessLevel.Public
						eStep := ParseStep.None
						aFields:Clear()
						sWord:Length := 0
						cRealChar := ' '
						lEscapedWord := FALSE
					END IF
				ENDIF

				IF state:nBracketCount == 0 .and. .not. state:lFindingType
					IF cOldChar == '{' .or. cOldChar == '['
						SWITCH cOldChar
						CASE  '{'
							state:cBracketOpen := '{'
							state:cBracketClose := '}'
						CASE '['
							state:cBracketOpen := '['
							state:cBracketClose := ']'
						END SWITCH
						state:nBracketCount := 1
					END IF
				END IF


				IF nChar == nLineLen
					cChar := ' '
				ELSE
					cChar := cLine[nChar]
				ENDIF
				cRealChar := cChar
				nChar ++
				
				IF state:lFirstChar
					IF cOldChar != ' ' .and. cOldChar != '\t'
						state:lFirstChar := FALSE
					END IF
				END IF
				
				lBeforeLexerChange := FALSE
				DO CASE
				CASE eLexer == LexerStep.BlockComment
					IF cChar == '/' .and. cOldChar == '*'
						eLexer := LexerStep.None
						cChar := ' ' // if next char is '*', we shouldn't go to BlockComment mode again
					ENDIF
					LOOP
				CASE cChar == '"' .and. eLexer != LexerStep.Quote .and. .not. (eLexer == LexerStep.DoubleQuote .and. lEscapedString .and. cOldChar == '\\')
					IF eLexer == LexerStep.DoubleQuote
						eLexer := LexerStep.None
						LOOP
					ELSE
						eLexer := LexerStep.DoubleQuote
						lEscapedString := cOldChar == 'e'
						lBeforeLexerChange := TRUE
						cChar := ' '
					END IF
				CASE cChar == '\'' .and. eLexer != LexerStep.DoubleQuote
					IF eLexer == LexerStep.Quote
						eLexer := LexerStep.None
						LOOP
					ELSE
						eLexer := LexerStep.Quote
						lBeforeLexerChange := TRUE
						cChar := ' '
					END IF
				CASE eLexer == LexerStep.Quote .or. eLexer == LexerStep.DoubleQuote
					LOOP
				CASE cChar == '/' .and. cOldChar == '/'
					eLexer := LexerStep.Comment
					EXIT
				CASE cChar == '*' .and. cOldChar == '/'
					eLexer := LexerStep.BlockComment
					cChar := ' ' // if next char is '/', we shouldn't go out of BlockComment mode again
					LOOP
				CASE cChar == '/'
					IF nChar < nLineLen .and. (cLine[nChar] == '/' .or. cLine[nChar] == '*') // about to go into comment mode
						lBeforeLexerChange := TRUE
						cChar := ' '
					END IF
				END CASE

				IF state:lIgnore .or. lContinueNextLine
					LOOP
				ENDIF
				
				// Ignore code inside {..} , [..]
				IF state:nBracketCount != 0
					IF cChar == state:cBracketOpen
						state:nBracketCount ++
					ELSEIF cChar == state:cBracketClose
						state:nBracketCount --
					END IF
					IF state:nBracketCount != 0
						LOOP
					END IF
				END IF
				
				IF cChar == ';' .and. sWord:Length == 0
					LOOP
				END IF
				
				lIsSpaceChar := cChar == ' ' .or. cChar == '\t'
				IF lIsSpaceChar
					IF sWord:Length == 0
						LOOP
					END IF
					lIsBreakChar := FALSE
				ELSE
					lIsBreakChar := CodeManager.hBrk:ContainsKey(cChar)
				END IF
				IF .not. (lIsBreakChar .or. lIsSpaceChar)
					sWord:Append(cChar)
					IF cOldChar == '@'
						lEscapedWord := TRUE
					END IF
					LOOP
				ENDIF
				// End of lexing
				
				// Parsing
				IF sWord:Length == 0
					cWord := ""
					cUpperWord := ""
				ELSE
					cWord := sWord:ToString()
					cUpperWord := cWord:ToUpper()
				END IF
				DO CASE
				CASE state:lFirstChar .and. cChar == '#'
					eStep := ParseStep.AfterSharp
				CASE cChar == ',' .and. state:lField .and. state:lNameFound .and. eStep != ParseStep.AfterAs
					state:lNameFound := FALSE
					state:lEntityFound := FALSE
				CASE sWord:Length == 0 .and. .not. state:lInParams .and. .not. state:lFindingType
					IF cChar == '('
						IF state:lNameFound .and. oInfo:aParams == NULL
							state:lInParams := TRUE
						END IF
					END IF
				CASE .not. lEscapedWord .and. CodeManager.hVis:ContainsKey(cUpperWord)
					state:lVisFound := TRUE
					IF .not. lIntellisense
						cModifiers += cUpperWord + " "
					END IF
					DO CASE
					CASE cUpperWord == "PROTECT" .or. cUpperWord == "PROTECTED" .or. cUpperWord == "INSTANCE"
						eAccessLevel := AccessLevel.Protected
					CASE cUpperWord == "HIDDEN" .or. cUpperWord == "PRIVATE"
						eAccessLevel := AccessLevel.Hidden
					CASE cUpperWord == "INTERNAL"
						eAccessLevel := AccessLevel.Internal
					CASE cUpperWord == "STATIC"
						eAccessLevel := AccessLevel.Static  // must be removed
						state:lStatic := TRUE
					CASE cUpperWord == "CONST"
						state:lStatic := TRUE
					CASE cUpperWord == "PARTIAL"
						state:lPartial := TRUE
					END CASE
					IF lIntellisense
						IF System.Array.IndexOf(<STRING>{"PROTECT" , "PROTECTED", "INSTANCE" , "EXPORT" , "PUBLIC" , "PRIVATE" , "HIDDEN" , "INTERNAL" , "MEMBER" , "GLOBAL"} , cUpperWord) != -1
							// Allow multiple names in same line
							state:lField := TRUE
						END IF
					END IF
				CASE .not. lEscapedWord .and. CodeManager.hEnt:ContainsKey(cUpperWord)
					lInEnum := FALSE
					state:lField := FALSE
					IF state:lEntityFound
						state:lIgnore := TRUE
					ENDIF
					state:lEntityFound := TRUE
					state:lEntityIsClass := System.Array.IndexOf(<STRING>{"CLASS","STRUCTURE","STRUCT","INTERFACE","DELEGATE","ENUM","VOSTRUCT","UNION"} , cUpperWord) != -1
					IF eStep == ParseStep.AfterEnd .and. state:lEntityIsClass
						state:lEntityFound := FALSE
						state:lEntityIsClass := FALSE
						state:lIgnore := TRUE
						lInEnum := FALSE
						cClass := ""
						IF oInfo != NULL
							oInfo:nLength := nLine - oInfo:nLine
							oInfo:nEndClassLine := nLine
							oInfo := NULL
						ENDIF
					ELSE
						lInEnum := cUpperWord == "ENUM"
						IF oInfo != NULL
							oInfo:nLength := nLine - oInfo:nLine
						ENDIF
						oInfo := ParseInfo{}
						oInfo:eType := CodeManager.GetEntityType(cUpperWord)
						IF state:lEntityIsClass
							DO CASE
							CASE cUpperWord == "CLASS"
								oInfo:cInherit := "System.Object"
							CASE cUpperWord == "STRUCTURE" .or. cUpperWord == "STRUCT"
								oInfo:cInherit := "System.ValueType"
							CASE cUpperWord == "DELEGATE"
								oInfo:cInherit := "System.MultiCastDelegate"
								oInfo:cRetType := "USUAL" // Default
							CASE cUpperWord == "ENUM"
								oInfo:cInherit := "System.Enum"
								oInfo:cRetType := "INT"
								cEnumType := "INT"
							OTHERWISE
								oInfo:cInherit := ""
							END CASE
						ELSE
							IF oInfo:eType == EntityType._Method .or. oInfo:eType == EntityType._Access .or. ;
								oInfo:eType == EntityType._Function .or. oInfo:eType == EntityType._Global
								oInfo:cRetType := "USUAL" // Default
							ELSE
								oInfo:cRetType := ""
							END IF
						END IF
						oInfo:lStatic := state:lStatic
						oInfo:eAccessLevel := eAccessLevel
						oInfo:cModifiers := cModifiers
						cModifiers := ""
						IF oInfo:eType == EntityType._Constructor .or. oInfo:eType == EntityType._Destructor
							state:lNameFound := TRUE // Dont't wait for a name, add it to the list now
							oInfo:nLine := nLine
							oInfo:cClass := cClass
							oInfo:cNameSpace := cNameSpace
//							oInfo:cName := cWord
							oInfo:cName := cClass // since there is no other name available
							aEntities:Add(oInfo)
							IF cChar == '('
								state:lInParams := TRUE
							END IF
						END IF
					END IF
				CASE state:lEntityFound .or. eStep == ParseStep.AfterBeginNamespace
					DO CASE
					CASE cUpperWord == "INHERIT"
						eStep := ParseStep.AfterInherit
						sFoundType:Length := 0
						n1 := 0;n2 := 0
					CASE cUpperWord == "AS"
						eStep := ParseStep.AfterAs
						sFoundType:Length := 0
						n1 := 0;n2 := 0
					CASE state:lInParams .and. cUpperWord == "REF"
						eStep := ParseStep.AfterAs
						sFoundType:Length := 0
						n1 := 0;n2 := 0
					CASE eStep == ParseStep.AfterInherit .or. eStep == ParseStep.AfterAs .or. ;
						eStep == ParseStep.AfterBeginNamespace .or. .not. state:lNameFound
						
						IF eStep == ParseStep.AfterInherit .or. eStep == ParseStep.AfterAs
							// Waiting for type that may be generic, array
							state:lFindingType := TRUE
							sFoundType:Append(sWord:ToString())
							sWord:Length := 0
							DO WHILE .not. lBeforeLexerChange .and. nChar < nLineLen .and. (cChar == ' ' .or. cChar == '\t')
								cOldChar := cChar
								cChar := cLine[nChar]
								IF cChar != ' ' .and. cChar != '\t' .and. cChar != '[' .and. cChar != '<'
									cChar := ' '
									EXIT
								END IF
								nChar ++
							END DO
							DO CASE
							CASE cChar == '.'
								sFoundType:Append('.')
							CASE cChar == '['
								sFoundType:Append('[')
								n1 ++
							CASE cChar == ']'
								IF n1 > 0
									sFoundType:Append(']')
									n1 --
								END IF
							CASE cChar == '<'
								sFoundType:Append('<')
								n2 ++
							CASE cChar == '>'
								IF n2 > 0
									sFoundType:Append('>')
									n2 --
								END IF
							CASE (n1 != 0 .or. n2 != 0) .and. cChar != ' ' .and. cChar != '\t' .and. cChar != ';'
								sFoundType:Append(cChar)
							END CASE
							IF cChar == '.' .or. n1 != 0 .or. n2 != 0 .or. (cChar == ']' .and. nChar < nLineLen .and. cLine[nChar] == '[') // more dims
								LOOP
							END IF
							cWord := sFoundType:ToString()
							sFoundType:Length := 0
							
							state:lFindingType := FALSE

						ELSE // eStep == ParseStep.AfterBeginNamespace .or. .not. state:lNameFound

							// Waiting for simple type or method name that may contain dots
							IF cChar == '.'
								sWord:Append('.')
								LOOP
							END IF
							cWord := sWord:ToString()
							sWord:Length := 0

						END IF

						IF state:lEntityIsClass .and. .not. state:lNameFound
							cClass := cWord
						ENDIF

						DO CASE
						CASE state:lInParams
							oInfo:SetParamType(cWord)
							eStep := ParseStep.None
						CASE eStep == ParseStep.AfterInherit
							oInfo:cInherit := cWord
							eStep := ParseStep.None
							state:lIgnore := TRUE
						CASE eStep == ParseStep.AfterAs
							oInfo:cRetType := cWord
							IF lInEnum
								cEnumType := cWord
							ELSEIF state:lField
								FOR n := 0 UPTO aFields:Count - 1
									aFields[n]:cRetType := cWord
								NEXT
							END IF
							eStep := ParseStep.None
							state:lIgnore := TRUE
						CASE eStep == ParseStep.AfterBeginNamespace
							eStep := ParseStep.None
							aNameSpaces:Push(cWord)
							cNameSpace := GetNameSpace(aNameSpaces)
							state:lIgnore := TRUE
						CASE .not. state:lNameFound
							state:lNameFound := TRUE
							oInfo:nLine := nLine
							oInfo:cClass := cClass
							oInfo:cNameSpace := cNameSpace
							oInfo:cName := cWord
							IF oInfo:eType == EntityType._Class .and. state:lPartial
								oInfo:lPartial := TRUE
							END IF
							aEntities:Add(oInfo)
							state:lPartial := FALSE
						END CASE
					
					END CASE
					IF state:lInParams
						IF cChar == ','
							IF .not. state:lParam
								oInfo:AddParam(cWord)
							END IF
							state:lParam := FALSE
						ELSEIF .not. state:lParam .and. sWord:Length != 0
							oInfo:AddParam(cWord)
							state:lParam := TRUE
						END IF
					ENDIF

					IF cChar == '('
						state:lInParams := TRUE
					ELSEIF state:lInParams .and. cChar == ')'
						state:lInParams := FALSE
					END IF
//					lIgnore := TRUE
				CASE cUpperWord == "BEGIN"
					lInEnum := FALSE
					eStep := ParseStep.AfterBegin
				CASE eStep == ParseStep.AfterBegin
					lInEnum := FALSE
					IF cUpperWord == "NAMESPACE"
						eStep := ParseStep.AfterBeginNamespace
					ELSE
						state:lIgnore := TRUE
					END IF
				CASE cUpperWord == "END"
					lInEnum := FALSE
					eStep := ParseStep.AfterEnd
				CASE eStep == ParseStep.AfterEnd
					state:lIgnore := TRUE
					lInEnum := FALSE
					IF System.Array.IndexOf(<STRING>{"CLASS","STRUCTURE","STRUCT","INTERFACE","ENUM"} , cUpperWord) != -1
						cClass := ""
						IF oInfo != NULL
							oInfo:nLength := nLine - oInfo:nLine
							oInfo:nEndClassLine := nLine
							oInfo := NULL
						ENDIF
					ELSEIF cUpperWord == "NAMESPACE"
						IF aNameSpaces:Count != 0
							aNameSpaces:Pop()
							cNameSpace := GetNameSpace(aNameSpaces)
						END IF
					ENDIF
				
				CASE eStep == ParseStep.AfterDefine
					IF aDefines != NULL
						aDefines:Add(DefineInfo{cUpperWord , nLine - 1})
					END IF
					state:lIgnore := TRUE
				
				CASE eStep == ParseStep.AfterSharp
					lInEnum := FALSE
					IF cUpperWord == "DEFINE"
						eStep := ParseStep.AfterDefine
					ELSE
						state:lIgnore := TRUE
					ENDIF

//				CASE .not. lIsSpaceChar .and. .not. (cChar == ',' .and. state:lField)
				CASE .not. lIsSpaceChar .and. .not. state:lField
					state:lIgnore := TRUE
				CASE lIntellisense .and. (state:lField .or. lInEnum) .and. .not. state:lNameFound
					state:lNameFound := TRUE
					state:lEntityFound := TRUE
					oInfo := ParseInfo{}
					oInfo:eType := EntityType._IVar
					oInfo:cModifiers := cModifiers
					oInfo:lStatic := state:lStatic
					oInfo:eAccessLevel := eAccessLevel
					oInfo:cRetType := "USUAL"
					IF lInEnum
						oInfo:cRetType := cEnumType
					ELSE
						aFields:Add(oInfo)
						IF cChar == ','
							state:lNameFound := FALSE
							state:lEntityFound := FALSE
						END IF
					ENDIF
					cModifiers := ""
					oInfo:nLine := nLine
					oInfo:cClass := cClass
					oInfo:cNameSpace := cNameSpace
					oInfo:cName := cWord
					aEntities:Add(oInfo)
				CASE state:lFirstWord .or. state:lFirstChar
					state:lIgnore := TRUE
				END CASE

				sWord:Length := 0
				lEscapedWord := FALSE
				state:lFirstWord := FALSE
				// End of parsing
				
			END DO
			
		ENDDO
		
		IF oInfo != NULL
			oInfo:nLength := nLine - oInfo:nLine
		ENDIF
		
	RETURN

	INTERNAL METHOD GetEnumerator() AS IEnumerator
	RETURN SELF:aLines:GetEnumerator()

	PRIVATE  STATIC METHOD GetEntityType(cWord AS STRING) AS EntityType
		LOCAL eType AS EntityType
        
		DO CASE
		CASE cWord == "METHOD"
			eType := EntityType._Method
		CASE cWord == "CONSTRUCTOR"
			eType := EntityType._Constructor
		CASE cWord == "CLASS"
			eType := EntityType._Class
		CASE cWord == "DESTRUCTOR"
			eType := EntityType._Destructor
		CASE cWord == "ACCESS"
			eType := EntityType._Access
		CASE cWord == "ASSIGN"
			eType := EntityType._Assign
		CASE cWord == "FUNCTION" .or. cWord == "FUNC"
			eType := EntityType._Function
		CASE cWord == "PROCEDURE" .or. cWord == "PROC"
			eType := EntityType._Function
		CASE cWord == "ENUM"
			eType := EntityType._Enum
		CASE cWord == "STRUCTURE" .or. cWord == "STRUCT"
			eType := EntityType._Structure
		CASE cWord == "VOSTRUCT"
			eType := EntityType._VOStruct
		CASE cWord == "UNION"
			eType := EntityType._Union
		CASE cWord == "GLOBAL"
			eType := EntityType._Global
		CASE cWord == "DELEGATE"
			eType := EntityType._Delegate
		CASE cWord == "EVENT"
			eType := EntityType._Event
		CASE cWord == "INTERFACE"
			eType := EntityType._Interface
        OTHERWISE
            eType := EntityType._None
		END CASE
	RETURN eType
	
	PRIVATE  STATIC METHOD GetNameSpace(aNameSpaces AS Stack<STRING>) AS STRING
		LOCAL oEnumerator AS IEnumerator
		LOCAL cRet AS STRING
		cRet := ""
		oEnumerator := aNameSpaces:GetEnumerator()
		DO WHILE oEnumerator:MoveNext()
			cRet := (STRING)oEnumerator:Current + "." + cRet
		END DO
	RETURN cRet

	STATIC PRIVATE  hVis , hEnt AS Dictionary<STRING,STRING>
	STATIC PRIVATE  hBrk AS Dictionary<Char,Char>
	STATIC CONSTRUCTOR()
		CodeManager.InitHashTables()
	RETURN

	PRIVATE STATIC METHOD InitHashTables() AS VOID
		LOCAL aWords AS STRING[]
		LOCAL cBreak AS STRING
		LOCAL n AS INT
		
		aWords := <STRING>{"VIRTUAL", "PARTIAL", "_DLL", "ABSTRACT", "SEALED", ;
		"INTERNAL", "HIDDEN", "STATIC", "PROTECTED", "INSTANCE", "PROTECT", "PRIVATE", "PUBLIC", "EXPORT", "CONST", "INITONLY", "MEMBER" , "GLOBAL"}
		CodeManager.hVis := Dictionary<STRING,STRING>{20}
		FOR n := 1 UPTO aWords:Length
			CodeManager.hVis:Add(aWords[n] , aWords[n])
		NEXT
	
		aWords := <STRING>{"CLASS", "METHOD", "ACCESS", "ASSIGN", ;
		"CONSTRUCTOR" , "DESTRUCTOR", "FUNCTION", "PROCEDURE", "FUNC", "PROC",;
		"GLOBAL", "ENUM", "STRUCTURE", "VOSTRUCT", "STRUCT", "UNION", "DELEGATE", "EVENT"}
		CodeManager.hEnt := Dictionary<STRING,STRING>{20}
		FOR n := 1 UPTO aWords:Length
			CodeManager.hEnt:Add(aWords[n] , aWords[n])
		NEXT

		cBreak := e",./;:[]<>?{}`~!@#$%^&*()-=\\+|'\""
		CodeManager.hBrk := Dictionary<Char,Char>{50}
		FOR n := 0 UPTO cBreak:Length - 1
			CodeManager.hBrk:Add(cBreak[n] , cBreak[n])
		NEXT
		
	RETURN
	
END CLASS
