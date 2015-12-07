//=============================================================================
//  MuseScore
//  Music Composition & Notation
//
//  Note Names Plugin
//
//  Copyright (C) 2012 Werner Schweer
//  Copyright (C) 2013, 2014 Joachim Schmitz
//  Copyright (C) 2014 Jörn Eichler
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License version 2
//  as published by the Free Software Foundation and appearing in
//  the file LICENCE.GPL
//=============================================================================

import QtQuick 2.2
import MuseScore 1.0
import QtQuick.Dialogs 1.2
import Qt.labs.settings 1.0

MuseScore {
    id: noteNames2
    version: "0.5"
    description: qsTr("NoteNames 2 by KlaBueBaer")
    menuPath: "Plugins." + qsTr("Note Names 2")

    property int voiceYPosIndex : 0

    property variant voiceYPos : [-1.5, -3.0,
        13, 14.5,
        -1, -1,
        12, 12]

    property variant colors: [
        "#1259d0", // Voice 1 - Blue    18  89 208
        "#009234", // Voice 2 - Green    0 146  52
        "#c04400", // Voice 3 - Orange 192  68   0
        "#71167a", // Voice 4 - Purple 113  22 122
        "#000000", // black
    ]
    property string blackColor : "#000000"

    property variant userAccidentalTexts : [
        "?",
        "#",
         "b",
         "##",
         "bb",
         "natural",
         "flat-slash",
         "flat-slash2",
         "mirrored-flat2",
         "mirrored-flat",
         "mirrored-flat-slash",
         "flat-flat-slash",
         "sharp-slash",
         "sharp-slash2",
         "sharp-slash3",
         "sharp-slash4",
         "sharp arrow up",
         "sharp arrow down",
         "sharp arrow both",
         "flat arrow up",
         "flat arrow down",
         "flat arrow both",
         "natural arrow down",
         "natural arrow up",
         "natural arrow both",
         "sori",
         "koron"
    ]

    property variant
    tpcText : [
        "Fbb", // -1
        "Cbb",   // 0
        "Gbb",         "Dbb",         "Abb",        "Ebb",        "Bbb",        "Fb",        "Cb",        "Gb",        "Db",
        "Ab",        "Eb",        "Bb",        "F",        "C",        "G",        "D",        "A",        "E",        "B",
        "F#",        "C#",        "G#",        "D#",        "A#",        "E#",        "B#",        "F##",        "C##",
        "G##",        "D##",        "A##",        "E##",        "B##"
    ];

    property variant octaveSymbols : [
        ",,",  ",", " ", " ", "\'", "\'\'", "\'\'\'", "\'\'\'\'", "\'\'\'\'\'", "\'\'\'\'", "\'\'\'\'\'\'"
    ]

    property bool flgDebug : false
    property string noteNamesSeparator        : "\n"  //
    property bool flgShowOctaveSymbol       : true
    property bool flgShowOctaveNumber       : false
    property string lastUsedChordText         : " "
    property bool flgConvert2UpperLowerCase : true
    property bool  flgSuppressDuplicates     : false
    property bool flgGraceNotesProcessing   : false
    property bool flgUseVoiceColors : true
    property bool flgVerticalStyle : false   // horizontal orientation, if false
    property bool flgUseLocalization : true
    property string fontName : "Arial"
    property string fontSize : "30%"

    Settings {
        id: noteNames2settings
        category: "noteNames2settings"

        property alias activeDebugMessages: noteNames2.flgDebug
        property alias fontSize: noteNames2.fontSize
        property alias fontName: noteNames2.fontName
        property alias useLocalization: noteNames2.flgUseLocalization
        property alias showOctaveSymbol: noteNames2.flgShowOctaveSymbol
        property alias showOctaveNumber : noteNames2.flgShowOctaveNumber
        property alias convert2UpperLowerCase : noteNames2.flgConvert2UpperLowerCase
        property alias verticalStyle : noteNames2.flgVerticalStyle
        property alias useVoiceColors : noteNames2.flgUseVoiceColors
        property alias suppressDuplicates : noteNames2.flgSuppressDuplicates
    }

function debugMsg (pMsg) {
if (flgDebug == true) {
console.log(pMsg)
}
}

    function toggleColor(element, pColor) {
        if (element.color != blackColor)
            element.color = blackColor
        else
            element.color = pColor
    }

    function colorVoices(element, voice) {
        if (! flgUseVoiceColors)
            return

        var voiceColor = colors[voice % 4]

        switch (element.type) {
        case Element.STAFF_TEXT:
        case Element.REST:
            toggleColor(element, voiceColor)
            break

        case Element.CHORD :
            colorChordElements (element, voiceColor)
            break

        case Element.NOTE :
            colorSingleElement (element, voiceColor)
            colorChordElements (element.parent, voiceColor)
            colorSingleElement (element.accidental, voiceColor)
            for (var i = 0; i < element.dots.length; i++) {
                colorSingleElement (element.dots[i], voiceColor)
            }
            break

        default:
            console.log("Unknown element type: " + element.type)
            break
        }
    }

    function colorChordElements (element, voiceColor) {
        colorSingleElement (element.stem, voiceColor)
        colorSingleElement (element.hook, voiceColor)
        colorSingleElement (element.beam, voiceColor)
        colorSingleElement (element.stemSlash, voiceColor) // Acciaccatura
    }

    function colorSingleElement (element, voiceColor) {
        if (element)
            toggleColor (element, voiceColor)
    }

    function createNoteNames (cursor, voice, notes) {

        var itext  = newElement (Element.STAFF_TEXT);

        nameChord (voice, notes, itext);

        if (flgVerticalStyle == false) {
            if (voiceYPosIndex > 1) voiceYPosIndex = 0
        }
        else {
            voiceYPosIndex = 0
        }
        var vi = (voice * 2) + voiceYPosIndex++
        itext.pos.y =  voiceYPos [vi];

        /* ??? not clear to me
        if ((voice == 0) && (notes[0].pitch > 83))
           itext.pos.x = 1;
        */
        colorVoices(itext, voice)
        cursor.add (itext);
    }

    function nameChord (pVoice, notes, text) {
        var sep = "";
        var chordText = ""
        var chordTextPosX

        for (var notesIndex = notes.length; notesIndex > 0; notesIndex--) {
            var currentNote = notes [notesIndex - 1]
            if (typeof currentNote.tpc === "undefined")
                return
            
            chordText += sep;
            sep = noteNamesSeparator

            var currTonalPitchClass = currentNote.tpc
            var currNoteName = "";
            if (currTonalPitchClass >= -1 && currTonalPitchClass <= 33) {
                currNoteName = getLocalizedName(tpcText[currTonalPitchClass + 1]);
            }
            else {
                currNoteName = getLocalizedName("?");
            }
            
            var octaveNumb = Math.floor(currentNote.pitch / 12) - 1;
            /*
        currNoteName = currNoteName.replace("Hb", "B")
        currNoteName = currNoteName.replace("Ab", "As")
        currNoteName = currNoteName.replace("Eb", "Es")
*/
            // a workaround only: best way is to define all names in the localization-file with combined key <octave+name>
            if (octaveNumb >= 3 && flgConvert2UpperLowerCase) {
                currNoteName = currNoteName.toLowerCase();
            }
            /*
            currNoteName = currNoteName.replace("#", "is")
            if (currNoteName.length > 1) {
               currNoteName = currNoteName.replace("b", "es")
            }
*/
            if (flgShowOctaveNumber) {
                currNoteName += octaveNumb;
            }
            if (flgShowOctaveSymbol) {
                if (octaveNumb < 3) {
                    currNoteName = octaveSymbols[octaveNumb] + currNoteName;
                }
                else {
                    currNoteName += octaveSymbols[octaveNumb];
                }
            }

            chordText += currNoteName;
            if (currentNote.accidentalType !== Accidental.NONE) {
                // adjust the horizontal position of the text according to the position of the accidental
                chordTextPosX = currentNote.accidental.pos.x;
            }
            else {
                if (flgGraceNotesProcessing) {
                    chordTextPosX = currentNote.parent.pos.x
                }
                else {
                    chordTextPosX = currentNote.pos.x
                }
            }
            colorVoices (currentNote, pVoice)

            // change below false to true for courtesy- and microtonal accidentals
            // you might need to come up with suitable translations
            // only #, b, natural and possibly also ## seem to be available in UNICODE

            if (false) {
                var idx = notes[i].userAccidental;
                if (idx !== 0) {
                    if (idx >= 1 && idx <= 26) {
                        chordText = getLocalizedName(userAccidentalTexts[idx]) + chordText
                    }
                    else {
                        chordText = qsTr(userAccidentalTexts[0])
                    }
                }
            } // end if courtesy- and microtonal accidentals
        } // end for each note

        if (chordText != lastUsedChordText || flgSuppressDuplicates == false) {
            lastUsedChordText = chordText;
            chordText = "<font size=\"" + fontSize + "\" />" + chordText;
            chordText = "<font face=\"" + fontName + "\" />" + chordText;
            text.text = chordText
            text.pos.x = chordTextPosX
        }
    }

    function getLocalizedName (pLocalizationKey) {
        if (flgUseLocalization == true) {
            return qsTr(pLocalizationKey)
        }
        else {
            return pLocalizationKey
        }
    }

    function dumpSegment (pCursor) {

        if (pCursor.element && pCursor.element.type === Element.CLEF) {
            console.log("CLEF clef = ")
        }
        var an = pCursor.segment.annotations;

        for (var i = 0; i < an.length; i++) {
            var iType = an[i].type
            console.log("type = " + iType)
            if (iType == Element.TEMPO_TEXT) {
                console.log("Tempo Text: tempo="+an[i].tempo);
            }
            if (iType == Element.CLEF) {
                console.log("Clef: clef=");
            }
        }
    }

    onRun: {

        // check MuseScore version
        if (!(mscoreMajorVersion == 2 && (mscoreMinorVersion > 0 || mscoreUpdateVersion>0))) {
             errorDialog.showError(
                        "Minimum MuseScore Version 2.0.1 required for this plugin")
        }

        if (!(curScore)) {
            errorDialog.showError("Select a score before executing this plugin.")
            Qt.quit()
        }

debugMsg ("noteNames2 started ...")

        var cursor = curScore.newCursor();
        var startStaff, endStaff, endTick;
        var fullScore = false;
        var lastUsedChordText = "";

        cursor.rewind(1);

        var rewindValue = 1; // beginning of selection
        if (!cursor.segment) { // no selection
            fullScore = true;
            startStaff = 0; // start with 1st staff
            endStaff  = curScore.nstaves - 1; // and end with last
            rewindValue = 0; // beginning of score
        }
        else {
            startStaff = cursor.staffIdx;
            cursor.rewind(2);
            if (cursor.tick === 0) {
                // this happens when the selection includes
                // the last measure of the score.
                // rewind(2) goes behind the last segment (where
                // there's none) and sets tick=0
                endTick = curScore.lastSegment.tick + 1;
            }
            else {
                endTick = cursor.tick;
            }
            endStaff   = cursor.staffIdx;
        }

        if (flgVerticalStyle == false)
            noteNamesSeparator = "-"

        for (var staff = startStaff; staff <= endStaff; staff++) {
            for (var voice = 0; voice < 4; voice++) {
                cursor.voice    = voice;
                cursor.staffIdx = staff;

                for (cursor.rewind(rewindValue); cursor.segment && (fullScore || cursor.tick < endTick); cursor.next()) {
                    // dumpSegment(cursor)
                    var element = cursor.element
                    if (element && element.type === Element.CHORD) {
                        flgGraceNotesProcessing = true
                        var graceChords = element.graceNotes;
                        for (var i = 0; i < graceChords.length; i++) {
                            createNoteNames (cursor, voice, graceChords[i].notes);
                        }
                        flgGraceNotesProcessing = false
                        createNoteNames (cursor, voice, cursor.element.notes);
                    } // end if CHORD
                } // end for segment
            } // end for voice
        } // end for staff

        Qt.quit();
    } // end onRun

    MessageDialog {
        id: errorDialog
        visible: false
        title: qsTr("Error")
        text: "Error"
        onAccepted: {
             Qt.quit()
        }
        function showError(message) {
            text = qsTr(message)
            open()
        }
    }
}
