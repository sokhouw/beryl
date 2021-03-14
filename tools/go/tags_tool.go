package main

import (
	"fmt"
	"go/ast"
	"go/importer"
	"go/parser"
	"go/token"
	"go/types"
	"io"
	"os"
	"path/filepath"
	"strconv"
	"strings"
)

var Mode int

const (
	Creating int = iota
	Listing
)

func main() {
	switch os.Args[1] {
	case "create":
		if len(os.Args) != 3 {
			fmt.Fprintf(os.Stderr, "Invalid arguments\n")
			os.Exit(1)
		}
		err := os.Chdir(os.Args[2])
		if err != nil {
			fmt.Fprintf(os.Stderr, "Failed to chdir to '%s'", os.Args[2])
			os.Exit(1)
		}
		Mode = Creating
		Create(os.Stdout, ".")
	case "list":
		if len(os.Args) != 3 {
			fmt.Fprintf(os.Stderr, "Invalid arguments\n")
			os.Exit(1)
		}
		Mode = Listing
		List(os.Stdout, os.Args[2])
	case "find":
		if len(os.Args) != 4 {
			fmt.Fprintf(os.Stderr, "Invalid arguments: expected 3\n")
			os.Exit(1)
		}
		filename := os.Args[2]
		offset, err := strconv.Atoi(os.Args[3])
		if err != nil {
			fmt.Fprintf(os.Stderr, "Invalid arguments: %s not an integer\n", os.Args[3])
			os.Exit(1)
		}
		Find(filename, nil, offset)

	default:
		fmt.Fprintf(os.Stderr, "Invalid arguments\n")
		os.Exit(1)
	}
}

// -------------------------------------------------------------------------
// Creating tag files
// -------------------------------------------------------------------------

func Create(output io.Writer, dirname string) error {
	writeHeader(output)
	return filepath.Walk(dirname, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if strings.HasSuffix(path, ".go") {
			return create(output, path, nil)
		} else {
			return nil
		}
	})
}

func List(output io.Writer, filename string) error {
	return create(output, filename, nil)
}

func create(output io.Writer, filename string, src interface{}) error {
	fset := token.NewFileSet()
	file, err := parser.ParseFile(fset, filename, src, parser.ParseComments)
	if err == nil {
		for _, decl := range file.Decls {
			addDecl(output, filename, fset, file, decl)
		}
		return nil
	} else {
		return err
	}
}

func addDecl(output io.Writer, filename string, fset *token.FileSet, file *ast.File, node ast.Node) {
	switch node.(type) {
	case *ast.FuncDecl:
		decl := node.(*ast.FuncDecl)
		pkg := file.Name.Name
		recv := ""
		if decl.Recv != nil {
			if decl.Recv.List != nil {
				recvType := decl.Recv.List[0].Type
				switch recvType.(type) {
				case *ast.StarExpr:
					expr := recvType.(*ast.StarExpr).X
					ident, ok := expr.(*ast.Ident)
					if ok {
						if Mode == Listing {
							recv = "(* " + ident.Name + ") "
						} else {
							recv = "(" + ident.Name + ")"
						}
					}
				case *ast.Ident:
					ident := recvType.(*ast.Ident)
					if Mode == Listing {
						recv = "(" + ident.Name + ") "
					} else {
						recv = "(" + ident.Name + ")"
					}
				}
			}
		}
		line := fset.Position(decl.Pos()).Line
		if Mode == Listing {
			writeTag(output, recv+decl.Name.Name, filename, line, "f")
		} else {
			writeTag(output, pkg+"."+recv+decl.Name.Name, filename, line, "f")
		}
	case *ast.GenDecl:
		decl := node.(*ast.GenDecl)
		for _, spec := range decl.Specs {
			addSpec(output, filename, fset, file, spec)
		}
	}
}

func addSpec(output io.Writer, filename string, fset *token.FileSet, file *ast.File, spec ast.Spec) {
	pkg := file.Name.Name
	switch spec.(type) {
	case *ast.ValueSpec:
		for _, v := range spec.(*ast.ValueSpec).Names {
			writeTag(output, pkg+"."+v.Name, filename, fset.Position(v.Pos()).Line, "v")
		}
	case *ast.TypeSpec:
		typeSpec := spec.(*ast.TypeSpec)
		line := fset.Position(typeSpec.Pos()).Line
		writeTag(output, pkg+"."+typeSpec.Name.Name, filename, line, "t")
	}
}

func writeHeader(output io.Writer) {
	io.WriteString(output, "!_TAG_FILE_FORMAT\t2\n!_TAG_FILE_SORTED\t1\n")
}

func writeTag(output io.Writer, name string, filename string, line int, kind string) {
	if Mode == Listing {
		io.WriteString(output, fmt.Sprintf("%s\t%s\t%v\t%s\n", name, filename, strconv.Itoa(line), kind))
	} else {
		io.WriteString(output, fmt.Sprintf("%s\t%s\t%v;\"\t%s\n", name, filename, strconv.Itoa(line), kind))
	}
}

// -------------------------------------------------------------------------
// Using tag files
// -------------------------------------------------------------------------

type context struct {
	offset int
	path   []*ast.Node
}

type visitor struct {
	path    []*ast.Node
	context *context
}

func Find(filename string, src interface{}, offset int) {
	fset := token.NewFileSet()
	info := types.Info{
		Types:      make(map[ast.Expr]types.TypeAndValue),
		Defs:       make(map[*ast.Ident]types.Object),
		Uses:       make(map[*ast.Ident]types.Object),
		Implicits:  make(map[ast.Node]types.Object),
		Selections: make(map[*ast.SelectorExpr]*types.Selection),
		Scopes:     make(map[ast.Node]*types.Scope)}
	file, err := parser.ParseFile(fset, filename, src, parser.ParseComments)
	if err == nil {
		importer := importer.Default()
		conf := types.Config{Importer: importer}
		_, err := conf.Check(filename, fset, []*ast.File{file}, &info)
		if err == nil {
			context := context{offset: offset}
			ast.Walk(visitor{path: make([]*ast.Node, 0), context: &context}, file)
			if len(context.path) > 2 {
				ident, _ := (ancestor(context.path, 0)).(*ast.Ident)
				if isCallExpr(ancestor(context.path, 1)) {
					fmt.Printf("%s.%s\n", file.Name.Name, ident.Name)
				} else if isSelectorExpr(ancestor(context.path, 1)) && isCallExpr(ancestor(context.path, 2)) {

					selector, _ := (ancestor(context.path, 1)).(*ast.SelectorExpr)
					selection := info.Selections[selector]
					if selection == nil {
						left, ok := selector.X.(*ast.Ident)
						if ok {
							fmt.Printf("%s.%s\n", left.Name, selector.Sel.Name)
						}
					} else {
						selection = info.Selections[selector]
						obj := selection.Obj()
						fun, _ := obj.(*types.Func)
						fmt.Printf("%s.(%s)%s\n", fun.Pkg().Name(), formatRecv(selection.Recv().String()), selector.Sel.Name)
					}
				}
			}
		}
	}
}

func formatRecv(recv string) string {
	s := strings.Split(recv, ".")
	return s[len(s)-1]
}

func ancestor(path []*ast.Node, nth int) ast.Node {
	return *path[len(path)-nth-1]
}

func isSelectorExpr(node ast.Node) bool {
	_, ok := node.(*ast.SelectorExpr)
	return ok
}

func isCallExpr(node ast.Node) bool {
	_, ok := node.(*ast.CallExpr)
	return ok
}

func (v visitor) Visit(node ast.Node) ast.Visitor {
	if node != nil {
		if int(node.Pos()) <= v.context.offset && v.context.offset <= int(node.End()) {
			v.path = append(v.path, &node)
			_, ok := node.(*ast.Ident)
			if ok {
				v.context.path = v.path
				return nil
			} else {
				return v
			}
		} else {
			return nil
		}
	} else {
		return nil
	}
}
