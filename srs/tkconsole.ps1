using namespace System;
using namespace Systems.Collections.Generic
import-module activedirectory
$PSver = $PSversiontable.PSversion
$ver = '2.0'
$dom = get-addomain -current localcomputer
$dom_forest = $dom.forest

class DomainHandler
{

    [PScustomobject]$query
    

    [hashtable]$filters = @{
        1 = 'Name';
        2 = 'EmployeeID';
        3 = 'ComputerName';
        4 = 'IPv4Address'
    }

    [void]display()
    {
        write-host $this.query.lockedout
    }

    [void]search([int]$filter_key, [string]$crit)
    {
        $filter = $this.filters[$filter_key]
        # if($filter -eq 1 -or $filter -eq 2)
        $this.query = get-aduser -filter "$filter -eq $crit" -properties name, employeeid, lockedout, manager
        $this.display()
        # get-adobject -filter "$filter -eq $crit" -properties name, employeeid | out-host
    }

    [void]unlock([int]$filter, [string]$crit)
    {
        write-host $filter $crit
    }

}

# Contains lists and actions used in ArgumentParser
class ArgumentContainer
{
    [System.Collections.ArrayList]$arg_lst
    [System.Collections.ArrayList]$arg_lst_to_consume
    [string]$arg_str
    [hashtable]$namespace = @{}
}

# Parses arguments and adds them to namespace hashtable. 
class ArgumentParser : ArgumentContainer
{
    # get argument values with -
    [string]$RX_OPT_ARG = "^-{1}[a-zA-Z0-9]+"
    # get argument values with --
    [string]$RX_OPT_LARG = "^-{2}[a-zA-Z0-9]+"
    # detect strings in quotes
    [string]$RX_QUOTE = "([^""]*)"
    # bad characters not to be used in args
    [string]$RX_BAD_CHARS = "[\*\?\]\[\^\+\`\!\@\#\$\%\&]"
    # check for comma separated values
    [string]$RX_COMMAS = "(,[\w]+)|([\w]+,)"

    [void]parse_args()
    {
        # clear namespace at beginning of invocation
        $this.namespace.clear()

        $this.arg_str = $this.get_arg_str()
        $this.arg_lst = $this.arg_str.split(' ')

        if($this.arg_lst[0] -match $this.RX_OPT_ARG -or $this.arg_lst[0] -match $this.RX_OPT_LARG)
        {
            throw '[ERROR] ' + $this.arg_lst[0] + ' must be a mode switch'
        }

        # initialize pointers
        [int]$p1 = 0
        [int]$p2 = 0

        # iter through argument list
        foreach($v in $this.arg_lst)
        {
            # mode argument will always be at index 0
            if($p1 -eq 0)
            {
                $this.namespace.mode = $v
                $p1++
                continue
            }


            # match arguments to values and add to namespace
            if($v -match $this.RX_OPT_ARG -or $v -match $this.RX_OPT_LARG)
            {
                # detect if argument contains a string value surrounded by quotations
                if($this.arg_lst[$p1 + 1].startswith('"'))
                {
                    # set p2 to p1
                    $p2 = $p1

                    # increment p2 until the other quote is found
                    do {$p2++} until ($this.arg_lst[$p2].endswith('"'))

                    # move pointer to beginning of string
                    $p1 += 1

                    # string value is between $p1 + 1 and $p2, assign to namespace
                    $this.namespace[$v] = $this.arg_lst[$p1..$p2]

                    # set p1 back
                    $p1 -= 1
                }
                
                elseif($this.arg_lst[$p1 + 1].contains(','))
                {
                    $p2 = $p1

                    [array]$sep_args = $this.arg_lst[$p1 + 1].split(',')
                    $p1 += 1
                    $this.namespace[$v] = $sep_args
                    $p1 -= 1
                }

                else
                {
                    # assign value to namespace
                    $this.namespace[$v] = $this.arg_lst[$p1 + 1]
                }
            }

            $p1++
 
        }

    }

    # get input from user
    [string]get_arg_str() 
    {
        $h = get-host
        $this.arg_str = $h.UI.readline()
        return $this.arg_str
    }

}

# startup art and information
function startup
{
    $art_source = join-path -path "$PSScriptRoot" -childpath "startup"
    $art_count = (get-childitem $art_source | measure-object).count
    $n = get-random -maximum $art_count
    $get_art = join-path -path $art_source -childpath $n
    get-content -raw $get_art | write-host
    write-host "by Jared Freed | GNU General Public License | ver $ver"
    write-host "Host: " -nonewline; write-host "$(hostname)" -foregroundcolor darkyellow
    if($dom -eq $null){write-host "Domain: " -nonewline; write-host "No domain detected" -foregroundcolor darkyellow}
    else{write-host "Domain: " -nonewline; write-host $dom_forest -foregroundcolor darkgreen}
    write-host "PS version: " -nonewline; write-host $PSver -foregroundcolor blue
    write-host "Enter " -nonewline; write-host "help " -nonewline -foregroundcolor darkgreen; write-host 'for usage'
}

function main
{
    $parser = [ArgumentParser]::new()
    $handler = [DomainHandler]::new()
    startup

    do
    {
        write-host "$(whoami)@tkc>" -nonewline
        $parser.parse_args()
        if($parser.namespace.mode -eq 'search')
        {
            $handler.search($parser.namespace.item('-f'), $parser.namespace.item('-i'))
        }
        elseif($parser.namespace.mode -eq 'unlock')
        {

        }
        elseif($parser.namespace.mode -eq 'modify')
        {

        }
        elseif($parser.namespace.mode -eq 'list')
        {

        }
        elseif($parser.namespace.mode -eq 'add')
        {

        }
        elseif($parser.namespace.mode -eq 'clear'){clear-host}

    } until ($parser.namespace.mode -eq 'quit')
}

main

