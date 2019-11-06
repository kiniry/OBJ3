/////////////////////////////////////////////////////////////////////////////
//  asmlists.cxx
//
//  basic list definitions for TRIM assembler (implementations).
//
//  Written by Lutz H. Hamel.
//  (c) copyright 1994.
/////////////////////////////////////////////////////////////////////////////

#include "asmlists.hxx"
#include "asm.hxx"
#include "fileio.h"

/////////////////////////////////////////////////////////////////////////////

void AsmSortOrder::Write (FILE * fp)
{
	long i;
	long j;
	
	fprintf(fp, "\n// Sort order.\n\n");

	fprintf(fp, "void Trim::InitSortOrder (void)\n");
	fprintf(fp, "{\n");

	fprintf(fp, "\tGetState()->GetSortOrder() = "
		    "mem(new SortOrder(%d));\n\n",
		GetSortTupleList()->Count());

	fprintf(fp, "\tSortList * sl;\n");
	fprintf(fp, "\tSortTuple * st;\n\n");

	for (i = 0; i < GetSortTupleList()->Count(); i++)
	{
		SortTuple * st = GetSortTupleList()->Get(i);
		SortList * sl = st->GetSortList();

		fprintf(fp, "\tsl = mem(new SortList(%d));\n", sl->Count());

		for (j = 0; j < sl->Count(); j++)
		{
			fprintf(fp, 
				"\tsl->Append(STRING(\"%s\"));\n",
				sl->Get(i));
		}

		fprintf(fp, 
			"\n\tst = mem(new SortTuple(STRING(\"%s\"),sl));\n", 
			st->GetSortName());

		fprintf(fp, "\tGetState()->GetSortOrder()->"
			    "GetSortTupleList()->Append(st);\n\n");
	}

	fprintf(fp, "}\n\n");
}

/////////////////////////////////////////////////////////////////////////////

void AsmOpTable::Write (FILE * fp, AsmSortOrder * so)
{
	long i;
	long j;
	
	fprintf(fp, "\n// Operator table.\n\n");

	fprintf(fp, "void Trim::InitOpTable (void)\n");
	fprintf(fp, "{\n");

	// we only need an operator table if we have a sort order.

	if (so->GetSortTupleList()->Count() == 0)
	{
		fprintf(fp, "\tGetState()->GetOpTable() = "
			    "mem(new OpTable(0));\n");
	}
	else
	{
		fprintf(fp, "\tGetState()->GetOpTable() = "
			    "mem(new OpTable(%d));\n\n", this->Count());

		fprintf(fp, "\tSortList * ar;\n");
		fprintf(fp, "\tOperator * op;\n\n");

		for (i = 0; i < Count(); i++)
		{
			Operator * op = Get(i);
			SortList * ar = op->GetArity();

			fprintf(fp, "\tar = mem(new SortList(%d));\n", 
				ar->Count());

			for (j = 0; j < ar->Count(); j++)
			{
				fprintf(fp, 
					"\tar->Append(STRING(\"%s\"));\n",
					ar->Get(j));
			}

			fprintf(fp, 
				"\n\top = "
				"mem(new Operator(STRING(\"%s\"),ar,"
				"STRING(\"%s\")));\n", 
				op->GetOpName(),
				op->GetCoArity());

			fprintf(fp, "\tGetState()->GetOpTable()->Append(op);"
				    "\n\n");
		}
	}

	fprintf(fp, "}\n\n");
}

/////////////////////////////////////////////////////////////////////////////

void InstrHandler::Write (char * out_file)
{
	FILE * fp = text_write_open(out_file, "w");

	if (!fp)
	{
		fprintf(stderr, "fatal -- could not open file `%s'.\n",
			out_file);
		exit(1);
	}

	// write the file

	WritePrologue(fp);
	WriteStringTable(fp);
	GetSortOrder()->Write(fp);
	GetOpTable()->Write(fp, GetSortOrder());
	WriteInstrs(fp);	
	WriteEpilogue(fp);
	
	text_close(fp);
}

/////////////////////////////////////////////////////////////////////////////

void InstrHandler::Gen (char * out_file)
{
	FILE * fp = text_write_open(out_file, "w");

	if (!fp)
	{
		fprintf(stderr, "fatal -- could not open file `%s'.\n",
			out_file);
		exit(1);
	}

	// write the file

	GenPrologue(fp);
	GetSortOrder()->Gen(fp);
	GetOpTable()->Gen(fp);
	GetInstrList()->Gen(fp);
	GenEpilogue(fp);
	
	text_close(fp);
}

/////////////////////////////////////////////////////////////////////////////

void InstrHandler::WritePrologue (FILE * fp)
{
	extern char * infilename;
	extern char * outfilename;

	time_t clock = time(NULL);

	fprintf(fp, 
	  "///////////////////////////////////////////////////////////////\n");
	fprintf(fp, "// Generated by TRIMASM Rev %s -- %s", 
		TRIMASM_VERSION, ctime(&clock));
	fprintf(fp, "// %s => %s\n", infilename, outfilename);
	fprintf(fp, 
	  "///////////////////////////////////////////////////////////////\n");
	fprintf(fp, "\n");

#ifdef INSTR_INLINE
	fprintf(fp, "#define INSTR_INLINE\n\n");
#endif
	fprintf(fp, "#include \"trim.hxx\"\n\n");

	fprintf(fp, "char * program_name = \"%s\";\n\n", 
		prog_name? prog_name : find_base(infilename));

}

/////////////////////////////////////////////////////////////////////////////

void InstrHandler::GenPrologue (FILE * fp)
{
	extern char * infilename;
	extern char * outfilename;

	time_t clock = time(NULL);

	fprintf(fp, "--- Generated by TRIMOPT Rev %s -- %s", 
		TRIMOPT_VERSION, ctime(&clock));
	fprintf(fp, "--- %s => %s\n", infilename, outfilename);
	fprintf(fp, "\n");
}

/////////////////////////////////////////////////////////////////////////////

void InstrHandler::WriteEpilogue (FILE * fp)
{
}

/////////////////////////////////////////////////////////////////////////////

void InstrHandler::GenEpilogue (FILE * fp)
{
}

/////////////////////////////////////////////////////////////////////////////

void InstrHandler::WriteStringTable (FILE * fp)
{
	fprintf(fp, "\n// String table.\n\n");

	long n_args = CountStringArgs();

	// iterate over the number of args and write the names of the entries 
	// out to the file into global data space.

	for (long i = 0; i < n_args; i++)
	{	
		fprintf(fp, "String s%d;\n", i);
	}

	fprintf(fp, "\n");

	// build an appropriate string table.

	BuildStringTable(n_args);

	// iterate over the table and write the names of the entries 
	// out to the file into the init functions

	fprintf(fp, "void Trim::InitStrings (void)\n");
	fprintf(fp, "{\n");

	for (long j = 0; j < n_args; j++)
	{	
		String s = string_table->Get(j);
		assert(s);
#ifdef DEBUG
		fprintf(stderr, "writing entry s%d = `%s'.\n", j, s);
#endif
		fprintf(fp, "\ts%d = STRING(\"%s\");\n", j, s);
	}

	fprintf(fp, "}\n\n");
}

/////////////////////////////////////////////////////////////////////////////

void InstrHandler::BuildStringTable (long size)
{
	// build an appropriate table.

	string_table = new StringList(size);
	mem_assert(string_table);

	// this is the ix which replaces the actual string pointer.
	long str_ix = 0;

	// iterate over the instrs and put the string arguments
	// into the table and replacing them with the ix in the
	// instrs.

	for (long i = 0; i < instr_list->Count(); i++)
	{
	        switch(instr_list->Get(i)->CountStringArgs())
	        {
		case 0:	// nothing
			break;

		case 1:
			EnterOperand(instr_list->Get(i), 0, str_ix++);
	                break;

		case 2:
			EnterOperand(instr_list->Get(i), 0, str_ix++);
			EnterOperand(instr_list->Get(i), 1, str_ix++);
	                break;

		default:
			fprintf(stderr, "fatal -- case %d unknown.\n", 
			        instr_list->Get(i)->CountStringArgs());
			abort();
		}

	}
}

/////////////////////////////////////////////////////////////////////////////

void InstrHandler::EnterOperand (Instr * instr, long op_ix, long str_ix)
{
	// get the string operand at position `op_ix'
	String s = instr->GetOperand(op_ix);

	// put it in the string table.
	string_table->Append(s);

	// map the pointer as the `str_ix'.
	assert(instr->GetIxOperand(op_ix) != ERROR);
	instr->GetIxOperand(op_ix) = str_ix;
}

/////////////////////////////////////////////////////////////////////////////
// count the number of string arguments in the instructions stream.

long InstrHandler::CountStringArgs (void)
{
	long count = 0;

	for (long i = 0; i < instr_list->Count(); i++)
	{
		count += instr_list->Get(i)->CountStringArgs();
	}

	return count;
}

/////////////////////////////////////////////////////////////////////////////

void InstrHandler::WriteInstrs (FILE * fp)
{
	fprintf(fp, "\n// Program\n\n");

	fprintf(fp, "void Trim::Program (void)\n");
	fprintf(fp, "{\n");

	if (gflag)
	{
		fprintf(fp, "\tGetState()->Print();\n");
	}

	for (int i = 0; i < instr_list->Count(); i++)
	{
#ifdef DEBUG
		fprintf(stderr, "writing instr `%s'.\n", 
			ConvertTrimInstr(instr_list->Get(i)->GetInstr()));
#endif
		instr_list->Get(i)->WriteLabel(fp);
		instr_list->Get(i)->Translate(fp);

		if (gflag)
		{
			fprintf(fp, "\tGetState()->Print();\n");
		}
	}

	fprintf(fp, "}\n");
}

/////////////////////////////////////////////////////////////////////////////

void LabelRecord::Print (FILE * fp)
{
	fprintf(fp, "*** LabelRecord: `%s'\n", label? label : "<NIL>");

	if (def_point == LABEL_NOT_DEFINED)
	{
		fprintf(fp, "  def point: <undefined>\n");
	}
	else
	{
		fprintf(fp, "  def point: (%s:%d)\n", 
			def_point->GetFileName(),
			(int)def_point->GetLine());
	}

	fprintf(fp, "  ref points:\n");

	fprintf(fp, "\t");

	for (int i = 0; i < ref_points.Count(); i++)
	{
		fprintf(fp, "(%s:%d) ", 
			def_point->GetFileName(),
			(int)ref_points.Get(i)->GetLine());

		if ((i+1)%3 == 0 && i > 0)
		{
			fprintf(fp, "\n\t");
		}
	}

	fprintf(fp, "\n");
}

/////////////////////////////////////////////////////////////////////////////

LabelRecord * LabelTable::FindLabelRecord (String label)
{
	for (int i = 0; i < Count(); i++)
	{
		if (streq(Get(i).GetLabel(), label))
		{
			return &Get(i);
		}
	}

	return NULL;
}

/////////////////////////////////////////////////////////////////////////////

LabelRecord * LabelTable::FindLabelRecord (LabelAddr instr_ix)
{
	for (int i = 0; i < Count(); i++)
	{
		if (Get(i).GetDefPoint() == instr_ix)
		{
			return &Get(i);
		}
	}

	return NULL;
}

/////////////////////////////////////////////////////////////////////////////

void LabelTable::LabelDef (String label, LabelAddr instr_ix)
{
	LabelRecord * r = FindLabelRecord(label);

	if (r)
	{
		if (r->GetDefPoint() != LABEL_NOT_DEFINED)
		{
			fprintf(stderr, 
				"error -- "
				"repeated definition of label `%s' (%s:%d).\n",
				label,
				scanner_filename(),
				scanner_line());
			errors++;
		}

		r->GetDefPoint() = instr_ix;
	}
	else
	{
		LabelRecord lr;

		lr.GetLabel() = label;
		lr.GetDefPoint() = instr_ix;

		Append(lr);
	}
}

/////////////////////////////////////////////////////////////////////////////

void LabelTable::LabelRef (String label, LabelAddr instr_ix)
{
	LabelRecord * r = FindLabelRecord(label);

	if (r)
	{
		r->GetRefPoints()->Append(instr_ix);
	}
	else
	{
		LabelRecord lr;

		lr.GetLabel() = label;
		lr.GetRefPoints()->Append(instr_ix);

		Append(lr);
	}
}

/////////////////////////////////////////////////////////////////////////////

void LabelTable::CheckInstrs (InstrList * instr_list)
{
	for (int i = 0; i < Count(); i++)
	{
		LabelRecord * r = &Get(i);

		if (r->GetDefPoint() == LABEL_NOT_DEFINED)
		{
			fprintf(stderr, 
				"error -- "
				"label `%s' referenced but not defined.\n",
				r->GetLabel());
			errors++;
			continue;
		}
		else if (r->GetDefPoint() != LABEL_NOT_DEFINED &&
			 r->GetRefPoints()->Count() == 0)
		{
			fprintf(stderr, 
				"warning -- "
				"label `%s' defined but not referenced.\n",
				r->GetLabel());
		}

		// we must pass this...
		assert(r->GetDefPoint() != LABEL_NOT_DEFINED &&
		       r->GetRefPoints()->Count() >= 0);

		// check the instructions.

		LabelAddrList * addr_list = r->GetRefPoints();

		for (int j = 0; j < addr_list->Count(); j++)
		{
			LabelAddr instr_ix = addr_list->Get(j);

#ifdef DEBUG
			fprintf(stderr,	"checking @%d defined @%d: ",
				instr_ix->GetLine(),
				(long) r->GetDefPoint()->GetLine());
			instr_ix->Gen(stderr);
#endif

			assert(instr_ix->GetInstr() == JUMPT ||
			       instr_ix->GetInstr() == JUMPF ||
			       instr_ix->GetInstr() == JUMP  ||
			       instr_ix->GetInstr() == CALL);
		}
	}
}

	
/////////////////////////////////////////////////////////////////////////////

void LabelTable::Print (FILE * fp)
{
	for (long i = 0; i < Count(); i++)
	{
		Get(i).Print(fp);
	}
}

/////////////////////////////////////////////////////////////////////////////
