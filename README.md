# BasicStateMachineAddon
Finite state machine addon to implement fsm to your proyects

This addon contains:
-  <b>StateMachineResource</b>: stores the data of the state machine
-  <b>StateMachineNode</b>: controls the flow of the state machine based on the given StateMachineResource
-  <b>Interface</b>: custom interface to facilitate the modification of an instance of StateMachineResource
-  <b>StateScript</b>: base class for all implementations of an state

## StateMachineNode
Node that executes the logic of the state machine. Add to your desired scene to have a state machine.

You will need to suply two elements to the StateMachineNode: a StateMachineResource and a `target`
The `target` can be any node as long as it has the methods, variables, etc that you want to use in your [StateScript](README.md#statescript)s

## Instancing StateMachineResource and using the interface
Data holder of the state machine.

<i>While you can modify the StateMachineResource by hand, I recommend to use the given interface to modify it as I will not explain the structure of the data (for now).</i>

To create an instance, right click in the File System section and select create new -> Resource -> StateMachineResource, this will create an empty StateMachineResource.
To modify data select your resource instance in the File System and on the bottom will appear the section 'Basic FSM Editor'.
![imagen](https://github.com/user-attachments/assets/98796706-c1bc-4590-ac9b-54bdc499dd94)

This interface has a few sections:
1. Top bar has two options: 'Map' and 'Parameters' section - first we begin at Map.
2. Grid with Nodes (left side): Main playground to instance your states and transitions
3. Node editor (right side): Node selected from the grid to edit

### Grid
Playground that allow to create empty states and transitions.

To create an empty state right click on an empty space of the grid and a menu will popup. Select 'create state' and a new empty State node will spawn.
<br/> You can also create a state by dragging a GDScript that inherits BaseScript into the grid.

To create a Transition you must press right click on top of a State. A popup will appear and select 'Add transition', then select press left click on another State to spawn a transition.
<br/><i>Keep in mind that the first node selected will be the origin and the second node will be the destination</i> 

You can delete Nodes by pressing right click on top of them and selecting Delete.

### Node Editor
By selecting a valid Node the editor of the node will appear. Currently there are 2 editors: one for States and another for Transitions

#### State editor
In the state property editor you can change the name and script attached to the state.
Two things to keep in mind:
-  State nodes names must be unique, if the new name collides with another state name it will not be saved
-  The attached script must be a inheritor of [StateScript](README.md#statescript) or other inheritors of [StateScript](README.md#statescript). State node script sources paths will not update the attached resource (like changing filename or directory).

#### Transition editor
Here you can edit on which conditions the transition will happen. If the conditions list is empty it will always transition to another state. <br/>
You can define different types of condition: 2 Parameter condition, single parameter condition and trigger condition.<br/>To know which parameters are available or add new ones see [Parameters](README.md#parameters) section

All conditions after the first one will show a combinator option button (AND or OR). The order of executions of the conditions are from top to down.

## Parameters
There are 2 sections, Integrated parameters that can t be deleted and custom parameters that you can add, modify and delete your own parameters.

There are 2 types of parameters: Triggers and floats<br/>
Triggers once activated will be deactivated again after a frame. By default are always false<br/>
Floats hold decimal values. By default are always 0

Parameter `time_on_state` will automatically count the amount of time spent in a particular node and will reset back to 0 on state change, usefull for timings.

Parameter names are unique. Deleting a parameter used in conditions will change them to blank. Parameters are used in conditions, see [conditions](README.md#transition-editor) section

## StateScript
Base class for all state scripts.
This class contains the following:

- var `smNode`: the StateMachineNode executing this StateScript
- var `target`: Node that will be affected by the execution of the StateScript. see [StateMachineNode](README.md#statemachinenode)
- function `_state_start()`: will execute when the state is transitioned into. <i>override to implement logic</i>
- function `_state_finish()`: will execute when the state is transitioned from (aka a new state will execute). <i>override to implement logic</i>
- function `_physics_process(delta)`: will execute every physics tick is it is the current state. <i>override to implement logic</i>
- function `_process(delta)`: will execute every process tick if it is the current state. <i>override to implement logic</i>
- function `set_parameter`: change a float parameter defined in [Parameters](README.md#parameters)
- function `activate_trigger`: will trigger the trigger defined in [Parameters](README.md#parameters)

Keep in mind, StateScript inherits from RefCounted, therefore wont have most methods that Nodes have
