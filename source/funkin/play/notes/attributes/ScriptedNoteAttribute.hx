package funkin.play.notes.noteattribute;

/**
 * A script that can be tied to a NoteKind.
 * Create a scripted class that extends NoteKind,
 * then call `super('noteAttribute')` in the constructor to use this.
 */
@:hscriptClass
class ScriptedNoteAttribute extends NoteAttribute implements polymod.hscript.HScriptedClass
{
}
