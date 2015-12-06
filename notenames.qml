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
import Qt.labs.settings 1.0

MuseScore {
    id: "noteNames2"
    version: "0.5"
    description: qsTr("NoteNames 2 by KlaBueBaer")
    menuPath: "Plugins." + qsTr("Note Names 2")

    property variant colors: [
        "#1259d0", // Voice 1 - Blue    18  89 208
        "#009234", // Voice 2 - Green    0 146  52
        "#c04400", // Voice 3 - Orange 192  68   0
        "#71167a", // Voice 4 - Purple 113  22 122
        "#000000", // black
    ]
    property variant blackColor : colors[4]

    property variant
    tpcText : [
        "Fbb", // -1
        "Cbb",   // 0
        "Gbb",
        "Dbb",
        "Abb",
        "Ebb",
        "Bbb",
        "Fb",
        "Cb",
        "Gb",
        "Db",
        "Ab",
        "Eb",
        "Bb",
        "F",
        "C",
        "G",
        "D",
        "A",
        "E",
        "B",
        "F#",
        "C#",
        "G#",
        "D#",
        "A#",
        "E#",
        "B#",
        "F##",
        "C##",
        "G##",
        "D##",
        "A##",
        "E##",
        "B##"
    ];

    property variant octaveSymbols : [
        ",,",  ",", " ", " ", "\'", "\'\'", "\'\'\'", "\'\'\'\'", "\'\'\'\'\'", "\'\'\'\'", "\'\'\'\'\'\'"
    ]
    property string noteNamesSeparator        : "\n"  //
    property bool flgShowOctaveSymbol       : true
    property bool flgShowOctaveNumber       : false
    property string lastUsedChordText         : " "
    property bool flgConvert2UpperLowerCase : true
    property bool  flgSuppressDuplicates     : false
    property bool flgGraceNotesProcessing   : false
    property bool flgUseVoiceColors : false
    property bool flgVerticalStyle : false   // horizontal orientation, if false


    Settings {
        id: "noteNames2settings"
        category: "noteNames2settings"
        property alias showOctaveSymbol: noteNames2.flgShowOctaveSymbol
        property alias showOctaveNumber : noteNames2.flgShowOctaveNumber
        property alias convert2UpperLowerCase : noteNames2.flgConvert2UpperLowerCase
        property alias verticalStyle : noteNames2.flgVerticalStyle
        property alias useVoiceColors : noteNames2.flgUseVoiceColors
        property alias suppressDuplicates : noteNames2.flgSuppressDuplicates

        // ...
    }


    function toggleColor(element, color) {
        if (element.color !== blackColor)
            element.color = blackColor
        else
            element.color = color
    }

    function colorVoices(element, voice) {
        if (flgUseVoiceColors == false)
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
        // beams would need special treatment as they belong to more than
        // one chord, esp. if they belong to an even number of chords,
        // so for now leave (or make) them black
        colorSingleElement (element.beam, blackColor)
        colorSingleElement (element.stemSlash, voiceColor) // Acciaccatura
    }

    function colorSingleElement (element, voiceColor) {
        if (element)
            toggleColor (element, voiceColor)
    }

    property int voiceYPosIndex : 0

    property variant voiceYPos : [-1.5, -3.0,
        13, 14.5,
        -1, -1,
        12, 12]


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
                currNoteName = qsTr(tpcText[currTonalPitchClass + 1]);
            }
            else {
                currNoteName = qsTr("?");
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
            if (currentNote.accidentalType != Accidental.NONE) {
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
                switch (notes[i].userAccidental) {
                case  0: break;
                case  1: chordText = qsTr("#") + chordText; break;
                case  2: chordText = qsTr("b") + chordText; break;
                case  3: chordText = qsTr("##") + chordText; break;
                case  4: chordText = qsTr("bb") + chordText; break;
                case  5: chordText = qsTr("natural") + chordText; break;
                case  6: chordText = qsTr("flat-slash") + chordText; break;
                case  7: chordText = qsTr("flat-slash2") + chordText; break;
                case  8: chordText = qsTr("mirrored-flat2") + chordText; break;
                case  9: chordText = qsTr("mirrored-flat") + chordText; break;
                case 10: chordText = qsTr("mirrored-flat-slash") + chordText; break;
                case 11: chordText = qsTr("flat-flat-slash") + chordText; break;
                case 12: chordText = qsTr("sharp-slash") + chordText; break;
                case 13: chordText = qsTr("sharp-slash2") + chordText; break;
                case 14: chordText = qsTr("sharp-slash3") + chordText; break;
                case 15: chordText = qsTr("sharp-slash4") + chordText; break;
                case 16: chordText = qsTr("sharp arrow up") + chordText; break;
                case 17: chordText = qsTr("sharp arrow down") + chordText; break;
                case 18: chordText = qsTr("sharp arrow both") + chordText; break;
                case 19: chordText = qsTr("flat arrow up") + chordText; break;
                case 20: chordText = qsTr("flat arrow down") + chordText; break;
                case 21: chordText = qsTr("flat arrow both") + chordText; break;
                case 22: chordText = qsTr("natural arrow down") + chordText; break;
                case 23: chordText = qsTr("natural arrow up") + chordText; break;
                case 24: chordText = qsTr("natural arrow both") + chordText; break;
                case 25: chordText = qsTr("sori") + chordText; break;
                case 26: chordText = qsTr("koron") + chordText; break;
                default: chordText = qsTr("?") + chordText; break;
                } // end switch userAccidental
            } // end if courtesy- and microtonal accidentals
        } // end for each note

        if (chordText != lastUsedChordText || flgSuppressDuplicates == false) {
            lastUsedChordText = chordText;
            chordText = "<font size=\"30%\"  />" + chordText;
            chordText = "<font face=\"Arial\" />" + chordText;
            text.text = chordText
            text.pos.x = chordTextPosX
        }

    }

    function dumpSegment (pCursor) {

        if (pCursor.element && pCursor.element.type == Element.CLEF) {
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
        if (typeof curScore === 'undefined')
            Qt.quit();
        
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
            if (cursor.tick == 0) {
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
                    if (element && element.type == Element.CHORD) {
                        flgGraceNotesProcessing = true
                        var graceChords = element.graceNotes;
                        for (var i = 0; i < graceChords.length; i++) {
                            createNoteNames (cursor, voice, graceChords[i].notes);
                        }
                        flgGraceNotesProcessing = false
                        createNoteNames (cursor, voice, cursor.element.notes);
                    } // end if CHORD
                } // end while segment
            } // end for voice
        } // end for staff

        noteNames2settings.showOctaveSymbol = noteNames2.flgShowOctaveSymbol
        noteNames2settings.useVoiceColors = false
        Qt.quit();
    } // end onRun
}
