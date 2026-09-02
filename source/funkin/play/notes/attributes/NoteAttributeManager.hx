package funkin.play.notes.NoteAttribute;

import funkin.data.song.SongData.SongNoteData;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.modding.events.ScriptEvent;
import funkin.ui.debug.charting.util.ChartEditorDropdowns;
import funkin.play.notes.attributes.ScriptedNoteAttribute;
import funkin.play.notes.attributes.NoteAttribute.NoteAttributeParam;
import funkin.util.macro.ClassMacro;

class NoteAttributeManager
{
  /**
   * Every built-in note kind class must be added to this list.
   * Thankfully, with the power of `ClassMacro`, this is done automatically.
   */
  static final BUILTIN_ATTRIBUTES:List<Class<NoteAttribute>> = ClassMacro.listSubclassesOf(NoteAttribute);

  /**
   * A map of all note kinds, keyed by their name.
   * This is used to retrieve note kinds by their name.
   */
  public static var noteAttributes:Map<String, NoteAttribute> = [];

  /**
   * An array of all note attributes present by default on notes.
   */
  public static var defaultNoteAttributes:Array<String> = [];

  /**
   * Retrieve a note kind by its name.
   * @param NoteAttribute The name of the note kind.
   * @return The note kind, or null if it doesn't exist.
   */
  public static function getNoteAttribute(?attribute:String):Null<NoteAttribute>
  {
    if (attribute == null) return null;
    return noteAttributes.get(attribute);
  }

  /**
   * Retrieve a list of known valid note kinds.
   * @return A list of note kinds
   */
  public static function listNoteAttributes():Array<String>
  {
    return noteAttributes.keyValues();
  }

  /**
   * Initialize custom behavior for note kinds.
   */
  public static function initialize():Void
  {
    clearAttributeCache();

    trace('Instantiating ${BUILTIN_ATTRIBUTES.length} built-in note attributes...');
    for (noteAttributeCls in BUILTIN_ATTRIBUTES)
    {
      var noteAttributeClsName:String = Type.getClassName(noteAttributeCls);
      if (
        noteAttributeClsName == 'funkin.play.notes.attributes.NoteAttribute'
        || noteAttributeClsName == 'funkin.play.notes.attributes.ScriptedNoteAttribute'
      ) continue;

      var attribute:NoteAttribute = Type.createInstance(noteAttributeCls, ['UNKNOWN']);

      if (attribute != null)
      {
        trace(' Loaded built-in note attribute: ${attribute.name}');
        noteAttributes.set(attribute.name, attribute);
        if (attribute.presentByDefault) defaultNoteAttributes.push(attribute.name);
      }
      else
      {
        trace(' Failed to load built-in note attribute: ${noteAttributeClsName}');
      }
    }

    var scriptedClassName:Array<String> = ScriptedNoteAttribute.listScriptClasses();
    if (scriptedClassName.length > 0)
    {
      trace('Instantiating ${scriptedClassName.length} scripted note attribute(s)...');
      for (scriptedClass in scriptedClassName)
      {
        try
        {
          var script:NoteAttribute = ScriptedNoteAttribute.scriptInit(scriptedClass, 'unknown');
          trace(' Initialized scripted note attribute: ${script.NoteAttribute}');
          noteAttributes.set(script.name, script);
          if (script.presentByDefault) defaultNoteAttributes.push(script.name);
        }
        catch (e)
        {
          trace(' FAILED to instantiate scripted note attribute: ${scriptedClass}');
          trace(e);
        }
      }
    }
  }

  #if FEATURE_MULTITHREADING
  public static function loadNoteAttributesAsync():lime.app.Future<LoadEntriesResult>
  {
    clearNoteAttributeCache();

    var perf:funkin.util.logging.Perf = new funkin.util.logging.Perf('loadNoteAttributesAsync');
    var promise:lime.app.Promise<LoadEntriesResult> = new lime.app.Promise<LoadEntriesResult>();
    var entryErrors:SynchronizedArray<
      {entryId:String, error:Any, ?entryCls:String}> = new SynchronizedArray();
    var scriptedNoteAttributeClasses:Array<String> = NoteAttribute.listScriptClasses();
    var entryCount:Int = 0;
    var loadedBaseNoteAttributes:Bool = false;

    var loadBaseNoteAttributesAsync:Void->Void = () -> {};
    var loadScriptedNoteAttributesAsync:Void->Void = () -> {};

    var checkAsyncProgress = () ->
    {
      var current:Int = noteAttributes.size() + entryErrors.length;
      if (current == entryCount)
      {
        if (!loadedBaseNoteAttributes)
        {
          loadedBaseNoteAttributes = true;
          loadScriptedNoteAttributesAsync();
          trace('Finished loading built-in note kinds (1/2) ($current / $entryCount)');
        }
        else
        {
          trace('Finished loading scripted note kinds (2/2) ($current / $entryCount)');
          promise.complete({
            entriesLoaded: noteAttributes.size(),
            entriesFailed: entryErrors.length
          });
          perf.print();
        }
      }
    }

    var onError:(String,
      {error:Any, entryCls:Null<String>}) -> Void = (entryId, state) ->
      {
        entryErrors.push({
          entryId: entryId,
          error: state.error
        });
        trace('  Failed to load note kind (${entryId}): ${state.error}');
        checkAsyncProgress();
      };

    var performLoadBaseNoteAttribute:Task = (currentState:State, workOutput:WorkOutput) ->
    {
      var NoteAttributeClsName:String = Type.getClassName(currentState.NoteAttributeCls);
      var NoteAttributeCls:Class<NoteAttribute> = currentState.NoteAttributeCls;

      try
      {
        var NoteAttribute:Null<NoteAttribute> = Type.createInstance(NoteAttributeCls, []);
        if (NoteAttribute != null)
        {
          workOutput.sendComplete({
            kind: NoteAttribute
          }, []);
        }
        else
        {
          workOutput.sendError({
            NoteAttributeId: NoteAttributeClsName,
            error: 'Failed to create built-in note kind ($NoteAttributeClsName)'
          });
        }
      }
      catch (e)
      {
        workOutput.sendError({
          eventId: NoteAttributeClsName,
          error: e
        });
      }
    }

    var performLoadScriptedNoteAttribute:Task = (currentState:State, workOutput:WorkOutput) ->
    {
      var entryCls:String = currentState.entryCls;
      try
      {
        var NoteAttribute:Null<NoteAttribute> = NoteAttribute.scriptInit(entryCls, 'UNKNOWN');
        if (NoteAttribute != null)
        {
          workOutput.sendComplete({
            kind: NoteAttribute,
            entryCls: entryCls
          }, []);
        }
        else
        {
          workOutput.sendError({
            entryCls: entryCls,
            error: 'Failed to create scripted note kind (${entryCls})'
          });
        }
      }
      catch (e)
      {
        workOutput.sendError({
          entryCls: entryCls,
          error: e,
        });
      }
    }

    var onBaseNoteAttributeLoaded:(String,
      {kind:NoteAttribute}) -> Void = (entryId, state) ->
      {
        noteAttributes.set(state.kind.NoteAttribute, state.kind);
        trace(' Loaded built-in note kind: ${state.kind.NoteAttribute} ($entryId)');
        checkAsyncProgress();
      };

    var onScriptedNoteAttributeLoaded:(String,
      {kind:NoteAttribute, entryCls:String}) -> Void = (_, state) ->
      {
        var entryId:String = state.kind.NoteAttribute;
        noteAttributes.set(entryId, state.kind);
        trace('  Loaded scripted note kind: ${entryId} (${state.entryCls}) (${noteAttributes.size()}+${entryErrors.length} / ${entryCount})');
        checkAsyncProgress();
      };

    loadBaseNoteAttributesAsync = () ->
    {
      entryCount = BUILTIN_KINDS.length;
      trace('Instantiating ${BUILTIN_KINDS.length} built-in note kinds...');

      if (BUILTIN_KINDS.length == 0)
      {
        checkAsyncProgress();
      }
      else
      {
        for (NoteAttributeCls in BUILTIN_KINDS)
        {
          var entryClsName:String = Type.getClassName(NoteAttributeCls);
          var baseNoteAttributeFuture = TaskHandler.performTask({
            task: performLoadBaseNoteAttribute,
            initialState: {
              NoteAttributeCls: NoteAttributeCls
            },
          }, new Promise<
            {kind:NoteAttribute}>());

          baseNoteAttributeFuture.onError(onError.bind(entryClsName));
          baseNoteAttributeFuture.onComplete(onBaseNoteAttributeLoaded.bind(entryClsName));
        }
      }
    }

    loadScriptedNoteAttributesAsync = () ->
    {
      entryCount = noteAttributes.size() + scriptedNoteAttributeClasses.length;
      trace('Instantiating ${scriptedNoteAttributeClasses.length} scripted note kind(s)...');

      if (scriptedNoteAttributeClasses.length == 0)
      {
        checkAsyncProgress();
      }
      else
      {
        for (entryCls in scriptedNoteAttributeClasses)
        {
          var scriptedNoteAttributeFuture = TaskHandler.performTask({
            task: performLoadScriptedNoteAttribute,
            initialState: {
              entryCls: entryCls
            }
          }, new lime.app.Promise<
            {
              kind:NoteAttribute,
              entryCls:String
            }>());

          scriptedNoteAttributeFuture.onError(onError.bind(entryCls));
          scriptedNoteAttributeFuture.onComplete(onScriptedNoteAttributeLoaded.bind(entryCls));
        }
      }
    }

    loadBaseNoteAttributesAsync();

    return promise.future;
  }
  #end

  /**
   * Calls the given event for note attribute scripts
   * @param event The event
   */
  public static function callEvent(event:ScriptEvent):Void
  {
    // if it is a note script event,
    // then only call the event for the specific note attribute script
    if (Std.isOfType(event, NoteScriptEvent))
    {
      var noteEvent:NoteScriptEvent = cast(event, NoteScriptEvent);

      var attributes:Array<String> = noteEvent?.note?.attributes;

      if (attributes != null)
      {
        for (attribute in attributes)
        {
          ScriptEventDispatcher.callEvent(attribute, event);
        }
      }
    }
    else // call the event for all note kind scripts
    {
      for (attribute in noteAttributes.iterator())
      {
        ScriptEventDispatcher.callEvent(attribute, event);
      }
    }
  }

  /**
   * Retrive custom params of the given note attribute
   * @param NoteAttribute Name of the note attribute
   * @return Array<NoteAttributeParam>
   */
  public static function getParams(attribute:Null<String>):Array<NoteAttributeParam>
  {
    if (attribute == null)
    {
      return [];
    }

    return noteAttributes.get(attribute)?.params ?? [];
  }

  /**
   * Clear the note kind cache.
   * Be sure to register the note kinds again before trying to use them.
   */
  public static function clearAttributeCache():Void
  {
    noteAttributes.clear();
  }
}
