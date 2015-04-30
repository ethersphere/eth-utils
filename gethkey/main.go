package main

import (
	"bufio"
	"fmt"
	"io/ioutil"
	"os"
	"path"

	"github.com/codegangsta/cli"
	"github.com/ethereum/go-ethereum/accounts"
	"github.com/ethereum/go-ethereum/cmd/utils"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/peterh/liner"
)

const (
	Version = ""
)

func main() {
	app := cli.NewApp()
	app.Name = "gethkey"
	app.Action = gethkey
	app.HideVersion = true // we have a command to print the version
	app.Usage = `

    gethkey [-p <passwordfile>|-d <keydir>] <address> <keyfile>

Exports the given account's private key into <keyfile> using the hex encoding canonical EC
format.
The user is prompted for a passphrase to unlock it.
For non-interactive use, the passphrase can be specified with the --password|-p flag:

    gethkey --password <passwordfile>  <address> <keyfile>

You can set an alternative key directory to use to find your ethereum encrypted keyfile.

Note:
As you can directly copy your encrypted accounts to another ethereum instance,
this import/export mechanism is not needed when you transfer an account between
nodes.
          `
	app.Flags = []cli.Flag{
		keyDirFlag,
		passwordFileFlag,
	}
	if err := app.Run(os.Args); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

var passwordFileFlag = cli.StringFlag{
	Name:  "password",
	Usage: "Path to password file (not recommended for interactive use)",
	Value: "",
}
var keyDirFlag = utils.DirectoryFlag{
	Name:  "keydir",
	Usage: "Key directory to be used",
	Value: utils.DirectoryString{path.Join(common.DefaultDataDir(), "keys")},
}

func unlockAccount(ctx *cli.Context, am *accounts.Manager, account string) (passphrase string) {
	var err error
	// Load startup keys. XXX we are going to need a different format
	// Attempt to unlock the account
	passphrase = getPassPhrase(ctx, "")
	accbytes := common.FromHex(account)
	if len(accbytes) == 0 {
		utils.Fatalf("Invalid account address '%s'", account)
	}
	err = am.Unlock(accbytes, passphrase)
	if err != nil {
		utils.Fatalf("Unlock account failed '%v'", err)
	}
	return
}

func getPassPhrase(ctx *cli.Context, desc string) (passphrase string) {
	passfile := ctx.GlobalString(passwordFileFlag.Name)
	if len(passfile) == 0 {
		fmt.Println(desc)
		auth, err := readPassword("Passphrase: ", true)
		if err != nil {
			utils.Fatalf("%v", err)
		}
		passphrase = auth
	} else {
		passbytes, err := ioutil.ReadFile(passfile)
		if err != nil {
			utils.Fatalf("Unable to read password file '%s': %v", passfile, err)
		}
		passphrase = string(passbytes)
	}
	return
}

func readPassword(prompt string, warnTerm bool) (string, error) {
	if liner.TerminalSupported() {
		lr := liner.NewLiner()
		defer lr.Close()
		return lr.PasswordPrompt(prompt)
	}
	if warnTerm {
		fmt.Println("!! Unsupported terminal, password will be echoed.")
	}
	fmt.Print(prompt)
	input, err := bufio.NewReader(os.Stdin).ReadString('\n')
	fmt.Println()
	return input, err
}

func gethkey(ctx *cli.Context) {
	account := ctx.Args().First()
	if len(account) == 0 {
		utils.Fatalf("account address must be given as first argument")
	}
	keyfile := ctx.Args().Get(1)
	if len(keyfile) == 0 {
		utils.Fatalf("keyfile must be given as second argument")
	}
	keydir := ctx.GlobalString(keyDirFlag.Name)
	ks := crypto.NewKeyStorePassphrase(keydir)
	am := accounts.NewManager(ks)
	auth := unlockAccount(ctx, am, account)

	err := am.Export(keyfile, common.FromHex(account), auth)
	if err != nil {
		utils.Fatalf("Account export failed: %v", err)
	}
}
