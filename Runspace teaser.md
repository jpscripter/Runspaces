## Embracing the magic of Powershell runspaces

A lot of people have hard about powershell runspaces before when they run google multi-threading, but is there more to them? Runspaces are the backbone to a lot of the advanced funcationality in powershell. Join us for a deep dive into what the runspaces and all of the crazy stuff they can do.

### Take Aways:
1. What and where runspaces are in powershell.
1. A basic understanding of how to multi-thread with powershell.
1.  How do do basic debugging and remote debugging with powershell. 

#### Overview 

1. Threading
	- What are they?
	- What can they do?
	- Why use them?
	- Special tricks

1. What are the treading options
	- Runspaces
	- jobs
	- workflow loops
	- Processes?

1. Into to Runspaces
	- What are they?
		- Initial session state
		- Runspacefactory
		- Runspace\RunspacePool
		- Powershell


1. How to customize
	- Adding variables, modules and startup scripts to the InitialSessionState
	- Adding script block and params to the powershell
	- Changing thread options in your runspace
	
	
1. Remote Debugging
	- Get-runspace
	- debug-runspace
	- Localscope runspace

1. Advanced Tricks
	- Credential impersonation
	- Remote Runspaces
