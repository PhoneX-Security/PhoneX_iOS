
all : _build.sh
	bash ./_buildMulti.sh
	@echo "Build done."
	
release : _buildMulti.sh
	PEX_BUILD=release bash ./_buildMulti.sh
	@echo "Build done."	
	
debug : _buildMulti.sh
	PEX_BUILD=debug bash ./_buildMulti.sh
	@echo "Build done."	

multi: 
	@bash ./_buildMulti.sh
	@echo "Build done."
	
multi-release: 
	@PEX_BUILD=release bash ./_buildMulti.sh
	@echo "Build done."
	
multi-debug: 
	@PEX_BUILD=debug bash ./_buildMulti.sh
	@echo "Build done."	
	
single: 
	@bash ./_build.sh
	@echo "Build done."
	
single-release: 
	@PEX_BUILD=release bash ./_build.sh
	@echo "Build done."
	
single-debug: 
	@PEX_BUILD=debug bash ./_build.sh
	@echo "Build done."	
	
.PHONY: clean

patch:
	@cd _source
	@if [ ! -f .patched_sources ]; then quilt push -a; touch .patched_sources; fi;
	@cd ..
	
unpatch:
	@cd _source
	@if [ -f .patched_sources ]; then quilt pop -af; rm .patched_sources; fi;
	@cd ..

cleanlib: 
	@find _source* -type f -name '*.a' -exec /bin/rm {} \;
	@find _libs -type f -name '*.a' -exec /bin/rm {} \; 
	 
cleandep:
	@find _source* -type f -name '.*.depend' -exec /bin/rm {} \;
	
cleanmk:	
	@cd _source && $(MAKE) clean
	@cd ..
	
clean: cleandep cleanlib cleanmk unpatch
	bash ./_cleanMulti.sh
	@echo "Project should be clean right now, including patches."
